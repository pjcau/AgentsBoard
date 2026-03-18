#ifndef COREBRIDGE_H
#define COREBRIDGE_H

#include <QObject>
#include <QString>
#include <agentsboard.h>

/// C++ RAII wrapper around the AgentsBoard C FFI.
/// Manages the ABCore lifecycle and provides a Qt-friendly interface.
class CoreBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int sessionCount READ sessionCount NOTIFY fleetChanged)
    Q_PROPERTY(double totalCost READ totalCost NOTIFY fleetChanged)
    Q_PROPERTY(int activeCount READ activeCount NOTIFY fleetChanged)
    Q_PROPERTY(int needsInputCount READ needsInputCount NOTIFY fleetChanged)
    Q_PROPERTY(int errorCount READ errorCount NOTIFY fleetChanged)
    Q_PROPERTY(QString version READ version CONSTANT)

public:
    explicit CoreBridge(QObject *parent = nullptr);
    ~CoreBridge() override;

    bool isValid() const { return m_core != nullptr; }

    // Fleet stats
    int sessionCount() const;
    double totalCost() const;
    int activeCount() const;
    int needsInputCount() const;
    int errorCount() const;
    QString version() const;

    // Session access
    ABSession sessionAt(int index) const;
    ABSession sessionById(const QString &id) const;

    // Session creation
    Q_INVOKABLE QString createSession(const QString &command,
                                       const QString &name,
                                       const QString &workdir);

    // Session actions
    Q_INVOKABLE void sendInput(const QString &sessionId, const QString &text);
    Q_INVOKABLE void archiveSession(const QString &sessionId);
    Q_INVOKABLE void deleteSession(const QString &sessionId);

    // Configuration
    Q_INVOKABLE bool loadConfig(const QString &path);
    Q_INVOKABLE int layout() const;
    Q_INVOKABLE void setLayout(int mode);
    Q_INVOKABLE double fontSize() const;
    Q_INVOKABLE void setFontSize(double size);

    // Raw handle access (for models)
    ABCore handle() const { return m_core; }

    // Refresh stats cache
    void refreshStats();

signals:
    void fleetChanged();

private:
    ABCore m_core = nullptr;

    // Cached stats
    int32_t m_stats[4] = {0, 0, 0, 0};
    double m_totalCost = 0.0;

    static void fleetCallbackTrampoline(int32_t eventType, void *context);
};

#endif // COREBRIDGE_H
