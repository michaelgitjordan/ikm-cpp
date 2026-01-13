#include "databasemanager.h"
#include <QDebug>
#include <QDateTime>

// Функция для корректного форматирования дат
static QString formatDateTime(const QVariant &value) {
    if (value.isNull()) {
        return "";
    }
    QDateTime dt = value.toDateTime();
    dt.setTimeSpec(Qt::UTC); // PostgreSQL возвращает в UTC
    return dt.toLocalTime().toString("dd.MM.yyyy HH:mm"); // Конвертируем в локальное
}

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
}

DatabaseManager::~DatabaseManager()
{
    closeDatabase();
}

bool DatabaseManager::connectToDatabase(const QString &host, const QString &dbName,
                                        const QString &user, const QString &password, int port)
{
    m_db = QSqlDatabase::addDatabase("QPSQL");
    m_db.setHostName(host);
    m_db.setDatabaseName(dbName);
    m_db.setUserName(user);
    m_db.setPassword(password);
    m_db.setPort(port);

    if (!m_db.open()) {
        m_lastError = m_db.lastError().text();
        emit errorOccurred(m_lastError);
        emit connectionStatusChanged(false);
        return false;
    }

    emit connectionStatusChanged(true);
    return true;
}

void DatabaseManager::closeDatabase()
{
    if (m_db.isOpen()) {
        m_db.close();
        emit connectionStatusChanged(false);
    }
}

bool DatabaseManager::isConnected() const
{
    return m_db.isOpen();
}

QVariantList DatabaseManager::getAllUsers()
{
    QVariantList users;
    QSqlQuery query(m_db);

    if (!query.exec("SELECT user_id, name, email, created_at FROM users ORDER BY name")) {
        emit errorOccurred(query.lastError().text());
        return users;
    }

    while (query.next()) {
        QVariantMap user;
        user["user_id"] = query.value(0).toLongLong();
        user["name"] = query.value(1).toString();
        user["email"] = query.value(2).toString();
        user["created_at"] = formatDateTime(query.value(3));
        users.append(user);
    }

    return users;
}

bool DatabaseManager::addUser(const QString &name, const QString &email)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO users (name, email) VALUES (:name, :email)");
    query.bindValue(":name", name);
    query.bindValue(":email", email.isEmpty() ? QVariant() : email);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

bool DatabaseManager::deleteUser(qint64 userId)
{
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM users WHERE user_id = :user_id");
    query.bindValue(":user_id", userId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

QVariantList DatabaseManager::getAllTasks(qint64 userId)
{
    QVariantList tasks;
    QSqlQuery query(m_db);

    QString sql = "SELECT t.task_id, t.user_id, u.name as user_name, t.title, "
                  "t.description, t.created_at, t.due_at, t.completed_at, "
                  "t.status_id, ts.status_name, t.priority "
                  "FROM tasks t "
                  "JOIN users u ON t.user_id = u.user_id "
                  "JOIN task_statuses ts ON t.status_id = ts.status_id ";

    if (userId > 0) {
        sql += "WHERE t.user_id = :user_id ";
    }

    sql += "ORDER BY t.priority DESC, t.created_at DESC";

    query.prepare(sql);

    if (userId > 0) {
        query.bindValue(":user_id", userId);
    }

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return tasks;
    }

    while (query.next()) {
        QVariantMap task;
        task["task_id"] = query.value(0).toLongLong();
        task["user_id"] = query.value(1).toLongLong();
        task["user_name"] = query.value(2).toString();
        task["title"] = query.value(3).toString();
        task["description"] = query.value(4).toString();
        task["created_at"] = formatDateTime(query.value(5));
        task["due_at"] = formatDateTime(query.value(6));
        task["completed_at"] = formatDateTime(query.value(7));
        task["status_id"] = query.value(8).toInt();
        task["status_name"] = query.value(9).toString();
        task["priority"] = query.value(10).toInt();

        // Получаем теги для задачи
        task["tags"] = getTaskTags(task["task_id"].toLongLong());

        tasks.append(task);
    }

    return tasks;
}

QVariantList DatabaseManager::getTasksByStatus(int statusId, qint64 userId)
{
    QVariantList tasks;
    QSqlQuery query(m_db);

    QString sql = "SELECT t.task_id, t.user_id, u.name as user_name, t.title, "
                  "t.description, t.created_at, t.due_at, t.completed_at, "
                  "t.status_id, ts.status_name, t.priority "
                  "FROM tasks t "
                  "JOIN users u ON t.user_id = u.user_id "
                  "JOIN task_statuses ts ON t.status_id = ts.status_id "
                  "WHERE t.status_id = :status_id ";

    if (userId > 0) {
        sql += "AND t.user_id = :user_id ";
    }

    sql += "ORDER BY t.priority DESC, t.created_at DESC";

    query.prepare(sql);
    query.bindValue(":status_id", statusId);

    if (userId > 0) {
        query.bindValue(":user_id", userId);
    }

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return tasks;
    }

    while (query.next()) {
        QVariantMap task;
        task["task_id"] = query.value(0).toLongLong();
        task["user_id"] = query.value(1).toLongLong();
        task["user_name"] = query.value(2).toString();
        task["title"] = query.value(3).toString();
        task["description"] = query.value(4).toString();
        task["created_at"] = formatDateTime(query.value(5));
        task["due_at"] = formatDateTime(query.value(6));
        task["completed_at"] = formatDateTime(query.value(7));
        task["status_id"] = query.value(8).toInt();
        task["status_name"] = query.value(9).toString();
        task["priority"] = query.value(10).toInt();
        task["tags"] = getTaskTags(task["task_id"].toLongLong());

        tasks.append(task);
    }

    return tasks;
}

QVariantList DatabaseManager::getTasksByTag(int tagId, qint64 userId)
{
    QVariantList tasks;
    QSqlQuery query(m_db);

    QString sql = "SELECT DISTINCT t.task_id, t.user_id, u.name as user_name, t.title, "
                  "t.description, t.created_at, t.due_at, t.completed_at, "
                  "t.status_id, ts.status_name, t.priority "
                  "FROM tasks t "
                  "JOIN users u ON t.user_id = u.user_id "
                  "JOIN task_statuses ts ON t.status_id = ts.status_id "
                  "JOIN task_tags tt ON t.task_id = tt.task_id "
                  "WHERE tt.tag_id = :tag_id ";

    if (userId > 0) {
        sql += "AND t.user_id = :user_id ";
    }

    sql += "ORDER BY t.priority DESC, t.created_at DESC";

    query.prepare(sql);
    query.bindValue(":tag_id", tagId);

    if (userId > 0) {
        query.bindValue(":user_id", userId);
    }

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return tasks;
    }

    while (query.next()) {
        QVariantMap task;
        task["task_id"] = query.value(0).toLongLong();
        task["user_id"] = query.value(1).toLongLong();
        task["user_name"] = query.value(2).toString();
        task["title"] = query.value(3).toString();
        task["description"] = query.value(4).toString();
        task["created_at"] = formatDateTime(query.value(5));
        task["due_at"] = formatDateTime(query.value(6));
        task["completed_at"] = formatDateTime(query.value(7));
        task["status_id"] = query.value(8).toInt();
        task["status_name"] = query.value(9).toString();
        task["priority"] = query.value(10).toInt();
        task["tags"] = getTaskTags(task["task_id"].toLongLong());

        tasks.append(task);
    }

    return tasks;
}

bool DatabaseManager::addTask(qint64 userId, const QString &title,
                              const QString &description, const QString &dueAt,
                              int priority, int statusId)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO tasks (user_id, title, description, due_at, priority, status_id) "
                  "VALUES (:user_id, :title, :description, :due_at, :priority, :status_id)");
    query.bindValue(":user_id", userId);
    query.bindValue(":title", title);
    query.bindValue(":description", description.isEmpty() ? QVariant() : description);

    QDateTime dueDateTime;
    if (!dueAt.isEmpty()) {
        dueDateTime = QDateTime::fromString(dueAt, "yyyy-MM-ddTHH:mm");
        dueDateTime.setTimeSpec(Qt::LocalTime); // Указываем, что это локальное время
    }
    query.bindValue(":due_at", dueAt.isEmpty() ? QVariant() : dueDateTime);

    query.bindValue(":priority", priority);
    query.bindValue(":status_id", statusId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

bool DatabaseManager::updateTask(qint64 taskId, const QString &title,
                                 const QString &description, const QString &dueAt,
                                 int priority, int statusId)
{
    QSqlQuery query(m_db);
    query.prepare("UPDATE tasks SET title = :title, description = :description, "
                  "due_at = :due_at, priority = :priority, status_id = :status_id "
                  "WHERE task_id = :task_id");
    query.bindValue(":task_id", taskId);
    query.bindValue(":title", title);
    query.bindValue(":description", description.isEmpty() ? QVariant() : description);

    QDateTime dueDateTime;
    if (!dueAt.isEmpty()) {
        dueDateTime = QDateTime::fromString(dueAt, "yyyy-MM-ddTHH:mm");
        dueDateTime.setTimeSpec(Qt::LocalTime); // Указываем, что это локальное время
    }
    query.bindValue(":due_at", dueAt.isEmpty() ? QVariant() : dueDateTime);

    query.bindValue(":priority", priority);
    query.bindValue(":status_id", statusId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

bool DatabaseManager::deleteTask(qint64 taskId)
{
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM tasks WHERE task_id = :task_id");
    query.bindValue(":task_id", taskId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

bool DatabaseManager::completeTask(qint64 taskId)
{
    QSqlQuery query(m_db);
    query.prepare("UPDATE tasks SET status_id = 2, completed_at = NOW() WHERE task_id = :task_id");
    query.bindValue(":task_id", taskId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

QVariantList DatabaseManager::getAllTags()
{
    QVariantList tags;
    QSqlQuery query(m_db);

    if (!query.exec("SELECT tag_id, tag_name, color, created_at FROM tags ORDER BY tag_name")) {
        emit errorOccurred(query.lastError().text());
        return tags;
    }

    while (query.next()) {
        QVariantMap tag;
        tag["tag_id"] = query.value(0).toInt();
        tag["tag_name"] = query.value(1).toString();
        tag["color"] = query.value(2).toString();
        tag["created_at"] = formatDateTime(query.value(3));
        tags.append(tag);
    }

    return tags;
}

bool DatabaseManager::addTag(const QString &tagName, const QString &color)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO tags (tag_name, color) VALUES (:tag_name, :color)");
    query.bindValue(":tag_name", tagName);
    query.bindValue(":color", color);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

bool DatabaseManager::deleteTag(int tagId)
{
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM tags WHERE tag_id = :tag_id");
    query.bindValue(":tag_id", tagId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

QVariantList DatabaseManager::getTaskTags(qint64 taskId)
{
    QVariantList tags;
    QSqlQuery query(m_db);

    query.prepare("SELECT t.tag_id, t.tag_name, t.color FROM tags t "
                  "JOIN task_tags tt ON t.tag_id = tt.tag_id "
                  "WHERE tt.task_id = :task_id ORDER BY t.tag_name");
    query.bindValue(":task_id", taskId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return tags;
    }

    while (query.next()) {
        QVariantMap tag;
        tag["tag_id"] = query.value(0).toInt();
        tag["tag_name"] = query.value(1).toString();
        tag["color"] = query.value(2).toString();
        tags.append(tag);
    }

    return tags;
}

bool DatabaseManager::addTagToTask(qint64 taskId, int tagId)
{
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO task_tags (task_id, tag_id) VALUES (:task_id, :tag_id) "
                  "ON CONFLICT (task_id, tag_id) DO NOTHING");
    query.bindValue(":task_id", taskId);
    query.bindValue(":tag_id", tagId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

bool DatabaseManager::removeTagFromTask(qint64 taskId, int tagId)
{
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM task_tags WHERE task_id = :task_id AND tag_id = :tag_id");
    query.bindValue(":task_id", taskId);
    query.bindValue(":tag_id", tagId);

    if (!query.exec()) {
        emit errorOccurred(query.lastError().text());
        return false;
    }
    return true;
}

QVariantList DatabaseManager::getAllStatuses()
{
    QVariantList statuses;
    QSqlQuery query(m_db);

    if (!query.exec("SELECT status_id, status_name, description FROM task_statuses ORDER BY status_id")) {
        emit errorOccurred(query.lastError().text());
        return statuses;
    }

    while (query.next()) {
        QVariantMap status;
        status["status_id"] = query.value(0).toInt();
        status["status_name"] = query.value(1).toString();
        status["description"] = query.value(2).toString();
        statuses.append(status);
    }

    return statuses;
}

QVariantMap DatabaseManager::getStatistics(qint64 userId)
{
    QVariantMap stats;
    QSqlQuery query(m_db);

    QString sql = "SELECT "
                  "(SELECT COUNT(*) FROM tasks WHERE status_id = 1%1) as active, "
                  "(SELECT COUNT(*) FROM tasks WHERE status_id = 2%1) as completed, "
                  "(SELECT COUNT(*) FROM tasks WHERE status_id = 3%1) as cancelled, "
                  "(SELECT COUNT(*) FROM tasks%2) as total";

    QString userFilter = userId > 0 ? QString(" AND user_id = %1").arg(userId) : "";
    QString userFilterWhere = userId > 0 ? QString(" WHERE user_id = %1").arg(userId) : "";

    sql = sql.arg(userFilter).arg(userFilterWhere);

    if (!query.exec(sql)) {
        emit errorOccurred(query.lastError().text());
        return stats;
    }

    if (query.next()) {
        stats["active"] = query.value(0).toInt();
        stats["completed"] = query.value(1).toInt();
        stats["cancelled"] = query.value(2).toInt();
        stats["total"] = query.value(3).toInt();
    }

    return stats;
}

bool DatabaseManager::executeQuery(QSqlQuery &query)
{
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        emit errorOccurred(m_lastError);
        return false;
    }
    return true;
}

QString DatabaseManager::getLastError() const
{
    return m_lastError;
}
