#include "SystemTray.h"
#include <QApplication>

SystemTray::SystemTray(CoreBridge *bridge, QObject *parent)
    : QObject(parent)
    , m_bridge(bridge)
{
    m_trayIcon = new QSystemTrayIcon(this);
    m_trayIcon->setToolTip("AgentsBoard");

    // Context menu
    m_menu = new QMenu();
    m_menu->addAction("Show AgentsBoard", []() {
        // TODO: Raise main window
    });
    m_menu->addSeparator();
    m_menu->addAction("Quit", []() {
        QCoreApplication::quit();
    });

    m_trayIcon->setContextMenu(m_menu);
    m_trayIcon->show();

    // Update tooltip on fleet changes
    connect(bridge, &CoreBridge::fleetChanged, this, &SystemTray::updateTooltip);
    updateTooltip();
}

void SystemTray::updateTooltip()
{
    QString tip = QString("AgentsBoard — %1 sessions, $%2")
        .arg(m_bridge->sessionCount())
        .arg(m_bridge->totalCost(), 0, 'f', 2);
    m_trayIcon->setToolTip(tip);
}
