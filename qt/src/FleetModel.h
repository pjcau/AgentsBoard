#ifndef FLEETMODEL_H
#define FLEETMODEL_H

#include <QAbstractListModel>
#include "CoreBridge.h"

/// Qt list model exposing fleet sessions to QML.
/// Wraps CoreBridge session access with proper Qt model roles.
class FleetModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        SessionIdRole = Qt::UserRole + 1,
        NameRole,
        StateRole,
        ProviderRole,
        CostRole,
        ProjectPathRole,
        StartTimeRole,
    };

    explicit FleetModel(CoreBridge *bridge, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

public slots:
    void refresh();

private:
    CoreBridge *m_bridge;
};

#endif // FLEETMODEL_H
