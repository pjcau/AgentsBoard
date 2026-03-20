#include "FleetModel.h"

FleetModel::FleetModel(CoreBridge *bridge, QObject *parent)
    : QAbstractListModel(parent)
    , m_bridge(bridge)
{
    connect(bridge, &CoreBridge::fleetChanged, this, &FleetModel::refresh);
}

int FleetModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_bridge->sessionCount();
}

QVariant FleetModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_bridge->sessionCount())
        return {};

    ABSession session = m_bridge->sessionAt(index.row());
    if (!session) return {};

    switch (role) {
    case SessionIdRole: {
        const char *id = ab_session_get_id(session);
        return id ? QString::fromUtf8(id) : QString();
    }
    case NameRole: {
        const char *name = ab_session_get_name(session);
        return name ? QString::fromUtf8(name) : QStringLiteral("Session");
    }
    case StateRole:
        return ab_session_get_state(session);
    case ProviderRole:
        return ab_session_get_provider(session);
    case CostRole:
        return ab_session_get_cost(session);
    case ProjectPathRole: {
        const char *path = ab_session_get_project_path(session);
        return path ? QString::fromUtf8(path) : QString();
    }
    case StartTimeRole:
        return ab_session_get_start_time(session);
    case CommandRole: {
        const char *cmd = ab_session_get_command(session);
        return cmd ? QString::fromUtf8(cmd) : QString();
    }
    default:
        return {};
    }
}

QHash<int, QByteArray> FleetModel::roleNames() const
{
    return {
        {SessionIdRole,  "sessionId"},
        {NameRole,       "name"},
        {StateRole,      "state"},
        {ProviderRole,   "provider"},
        {CostRole,       "cost"},
        {ProjectPathRole,"projectPath"},
        {StartTimeRole,  "startTime"},
        {CommandRole,    "command"},
    };
}

void FleetModel::refresh()
{
    beginResetModel();
    endResetModel();
}
