#include "ActivityModel.h"

ActivityModel::ActivityModel(CoreBridge *bridge, QObject *parent)
    : QAbstractListModel(parent)
    , m_bridge(bridge)
{
    connect(bridge, &CoreBridge::fleetChanged, this, &ActivityModel::refresh);
}

void ActivityModel::setSessionFilter(const QString &id)
{
    if (m_sessionFilter != id) {
        m_sessionFilter = id;
        emit sessionFilterChanged();
        refresh();
    }
}

int ActivityModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    QByteArray filterUtf8 = m_sessionFilter.toUtf8();
    const char *filter = m_sessionFilter.isEmpty() ? nullptr : filterUtf8.constData();
    return ab_activity_count(m_bridge->handle(), filter);
}

QVariant ActivityModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) return {};

    QByteArray filterUtf8 = m_sessionFilter.toUtf8();
    const char *filter = m_sessionFilter.isEmpty() ? nullptr : filterUtf8.constData();

    const char *type = nullptr;
    const char *details = nullptr;
    double timestamp = 0;
    double cost = 0;

    if (!ab_activity_get_event(m_bridge->handle(), filter, index.row(),
                                &type, &details, &timestamp, &cost)) {
        return {};
    }

    switch (role) {
    case TypeRole:
        return type ? QString::fromUtf8(type) : QString();
    case DetailsRole:
        return details ? QString::fromUtf8(details) : QString();
    case TimestampRole:
        return timestamp;
    case CostRole:
        return cost;
    default:
        return {};
    }
}

QHash<int, QByteArray> ActivityModel::roleNames() const
{
    return {
        {TypeRole,      "eventType"},
        {DetailsRole,   "details"},
        {TimestampRole, "timestamp"},
        {CostRole,      "cost"},
    };
}

void ActivityModel::refresh()
{
    beginResetModel();
    endResetModel();
}
