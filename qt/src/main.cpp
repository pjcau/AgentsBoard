#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

#include "CoreBridge.h"
#include "FleetModel.h"
#include "SessionModel.h"
#include "ActivityModel.h"
#include "TerminalWidget.h"
#include "SystemTray.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName("AgentsBoard");
    app.setOrganizationName("AgentsBoard");
    app.setApplicationVersion("0.9.0");

    // Register QML types
    qmlRegisterType<TerminalWidget>("AgentsBoard.Terminal", 1, 0, "TerminalWidget");

    // Initialize Swift Core via C FFI
    CoreBridge bridge;
    if (!bridge.isValid()) {
        qCritical("Failed to initialize AgentsBoard Core");
        return 1;
    }

    // Create models
    FleetModel fleetModel(&bridge);
    SessionModel sessionModel(&bridge);
    ActivityModel activityModel(&bridge);

    // System tray
    SystemTray tray(&bridge);

    // Setup QML engine
    QQmlApplicationEngine engine;

    // Expose models to QML
    engine.rootContext()->setContextProperty("coreBridge", &bridge);
    engine.rootContext()->setContextProperty("fleetModel", &fleetModel);
    engine.rootContext()->setContextProperty("sessionModel", &sessionModel);
    engine.rootContext()->setContextProperty("activityModel", &activityModel);

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
