#ifndef SYSTEMTRAY_H
#define SYSTEMTRAY_H

#include <QObject>
#include <QSystemTrayIcon>
#include <QMenu>
#include "CoreBridge.h"

/// System tray icon showing fleet cost summary.
class SystemTray : public QObject
{
    Q_OBJECT

public:
    explicit SystemTray(CoreBridge *bridge, QObject *parent = nullptr);

private slots:
    void updateTooltip();

private:
    CoreBridge *m_bridge;
    QSystemTrayIcon *m_trayIcon;
    QMenu *m_menu;
};

#endif // SYSTEMTRAY_H
