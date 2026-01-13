#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QString>
#include <QVariantMap>
#include <QVariantList>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    // Подключение к базе данных
    bool connectToDatabase(const QString &host, const QString &dbName,
                           const QString &user, const QString &password,
                           int port = 5432);
    void closeDatabase();
    bool isConnected() const;

    // Операции с пользователями
    Q_INVOKABLE QVariantList getAllUsers();
    Q_INVOKABLE bool addUser(const QString &name, const QString &email);
    Q_INVOKABLE bool deleteUser(qint64 userId);

    // Операции с задачами
    Q_INVOKABLE QVariantList getAllTasks(qint64 userId = -1);
    Q_INVOKABLE QVariantList getTasksByStatus(int statusId, qint64 userId = -1);
    Q_INVOKABLE QVariantList getTasksByTag(int tagId, qint64 userId = -1);
    Q_INVOKABLE bool addTask(qint64 userId, const QString &title,
                             const QString &description, const QString &dueAt,
                             int priority, int statusId);
    Q_INVOKABLE bool updateTask(qint64 taskId, const QString &title,
                                const QString &description, const QString &dueAt,
                                int priority, int statusId);
    Q_INVOKABLE bool deleteTask(qint64 taskId);
    Q_INVOKABLE bool completeTask(qint64 taskId);

    // Операции с тегами
    Q_INVOKABLE QVariantList getAllTags();
    Q_INVOKABLE bool addTag(const QString &tagName, const QString &color);
    Q_INVOKABLE bool deleteTag(int tagId);
    Q_INVOKABLE QVariantList getTaskTags(qint64 taskId);
    Q_INVOKABLE bool addTagToTask(qint64 taskId, int tagId);
    Q_INVOKABLE bool removeTagFromTask(qint64 taskId, int tagId);

    // Операции со статусами
    Q_INVOKABLE QVariantList getAllStatuses();

    // Статистика
    Q_INVOKABLE QVariantMap getStatistics(qint64 userId = -1);

signals:
    void errorOccurred(const QString &error);
    void connectionStatusChanged(bool connected);

private:
    QSqlDatabase m_db;
    QString m_lastError;

    bool executeQuery(QSqlQuery &query);
    QString getLastError() const;
};

#endif // DATABASEMANAGER_H
