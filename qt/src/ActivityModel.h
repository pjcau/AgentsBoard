#ifndef ACTIVITYMODEL_H
#define ACTIVITYMODEL_H

#include <QAbstractListModel>
#include "CoreBridge.h"

/// Qt list model exposing activity events to QML.
class ActivityModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString sessionFilter READ sessionFilter WRITE setSessionFilter NOTIFY sessionFilterChanged)

public:
    enum Roles {
        TypeRole = Qt::UserRole + 1,
        DetailsRole,
        TimestampRole,
        CostRole,
    };

    explicit ActivityModel(CoreBridge *bridge, QObject *parent = nullptr);

    QString sessionFilter() const { return m_sessionFilter; }
    void setSessionFilter(const QString &id);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

public slots:
    void refresh();

signals:
    void sessionFilterChanged();

private:
    CoreBridge *m_bridge;
    QString m_sessionFilter;
};

#endif // ACTIVITYMODEL_H
