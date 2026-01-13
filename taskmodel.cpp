#include "taskmodel.h"

TaskModel::TaskModel(DatabaseManager *dbManager, QObject *parent)
    : QObject(parent)
    , m_dbManager(dbManager)
    , m_currentUserId(-1)
    , m_filterStatusId(-1)
    , m_filterTagId(-1)
{
}

void TaskModel::setCurrentUserId(qint64 userId)
{
    if (m_currentUserId != userId) {
        m_currentUserId = userId;
        emit currentUserIdChanged();
        refreshAll();
    }
}

void TaskModel::refreshTasks()
{
    if (!m_dbManager || !m_dbManager->isConnected()) {
        return;
    }

    if (m_filterStatusId > 0) {
        m_tasks = m_dbManager->getTasksByStatus(m_filterStatusId, m_currentUserId);
    } else if (m_filterTagId > 0) {
        m_tasks = m_dbManager->getTasksByTag(m_filterTagId, m_currentUserId);
    } else {
        m_tasks = m_dbManager->getAllTasks(m_currentUserId);
    }

    emit tasksChanged();
}

void TaskModel::refreshUsers()
{
    if (!m_dbManager || !m_dbManager->isConnected()) {
        return;
    }

    m_users = m_dbManager->getAllUsers();
    emit usersChanged();
}

void TaskModel::refreshTags()
{
    if (!m_dbManager || !m_dbManager->isConnected()) {
        return;
    }

    m_tags = m_dbManager->getAllTags();
    emit tagsChanged();
}

void TaskModel::refreshStatuses()
{
    if (!m_dbManager || !m_dbManager->isConnected()) {
        return;
    }

    m_statuses = m_dbManager->getAllStatuses();
    emit statusesChanged();
}

void TaskModel::refreshStatistics()
{
    if (!m_dbManager || !m_dbManager->isConnected()) {
        return;
    }

    m_statistics = m_dbManager->getStatistics(m_currentUserId);
    emit statisticsChanged();
}

void TaskModel::refreshAll()
{
    refreshTasks();
    refreshUsers();
    refreshTags();
    refreshStatuses();
    refreshStatistics();
}

void TaskModel::filterByStatus(int statusId)
{
    m_filterStatusId = statusId;
    m_filterTagId = -1;
    refreshTasks();
}

void TaskModel::filterByTag(int tagId)
{
    m_filterTagId = tagId;
    m_filterStatusId = -1;
    refreshTasks();
}

void TaskModel::clearFilters()
{
    m_filterStatusId = -1;
    m_filterTagId = -1;
    refreshTasks();
}
