#ifndef TASKMODEL_H
#define TASKMODEL_H

#include <QObject>
#include <QVariantList>
#include "databasemanager.h"

class TaskModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList tasks READ tasks NOTIFY tasksChanged)
    Q_PROPERTY(QVariantList users READ users NOTIFY usersChanged)
    Q_PROPERTY(QVariantList tags READ tags NOTIFY tagsChanged)
    Q_PROPERTY(QVariantList statuses READ statuses NOTIFY statusesChanged)
    Q_PROPERTY(QVariantMap statistics READ statistics NOTIFY statisticsChanged)
    Q_PROPERTY(qint64 currentUserId READ currentUserId WRITE setCurrentUserId NOTIFY currentUserIdChanged)

public:
    explicit TaskModel(DatabaseManager *dbManager, QObject *parent = nullptr);

    QVariantList tasks() const { return m_tasks; }
    QVariantList users() const { return m_users; }
    QVariantList tags() const { return m_tags; }
    QVariantList statuses() const { return m_statuses; }
    QVariantMap statistics() const { return m_statistics; }
    qint64 currentUserId() const { return m_currentUserId; }

    void setCurrentUserId(qint64 userId);

    Q_INVOKABLE void refreshTasks();
    Q_INVOKABLE void refreshUsers();
    Q_INVOKABLE void refreshTags();
    Q_INVOKABLE void refreshStatuses();
    Q_INVOKABLE void refreshStatistics();
    Q_INVOKABLE void refreshAll();

    Q_INVOKABLE void filterByStatus(int statusId);
    Q_INVOKABLE void filterByTag(int tagId);
    Q_INVOKABLE void clearFilters();

signals:
    void tasksChanged();
    void usersChanged();
    void tagsChanged();
    void statusesChanged();
    void statisticsChanged();
    void currentUserIdChanged();

private:
    DatabaseManager *m_dbManager;
    QVariantList m_tasks;
    QVariantList m_users;
    QVariantList m_tags;
    QVariantList m_statuses;
    QVariantMap m_statistics;
    qint64 m_currentUserId;
    int m_filterStatusId;
    int m_filterTagId;
};

#endif // TASKMODEL_H
