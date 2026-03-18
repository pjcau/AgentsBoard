#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

#include "CoreBridge.h"
#include "FleetModel.h"
#include "SessionModel.h"
#include "SystemTray.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("AgentsBoard");
    app.setOrganizationName("AgentsBoard");
    app.setApplicationVersion("0.9.0");

    // Initialize Swift Core via C FFI
    CoreBridge bridge;
    if (!bridge.isValid()) {
        qCritical("Failed to initialize AgentsBoard Core");
        return 1;
    }

    // Create models
    FleetModel fleetModel(&bridge);
    SessionModel sessionModel(&bridge);

    // System tray
    SystemTray tray(&bridge);

    // Setup QML engine
    QQmlApplicationEngine engine;

    // Expose models to QML
    engine.rootContext()->setContextProperty("coreBridge", &bridge);
    engine.rootContext()->setContextProperty("fleetModel", &fleetModel);
    engine.rootContext()->setContextProperty("sessionModel", &sessionModel);

    // Load main QML
    const QUrl url(QStringLiteral("qrc:/AgentsBoard/qml/Main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );
    engine.load(url);

    return app.exec();
}
