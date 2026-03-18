#ifndef SESSIONMODEL_H
#define SESSIONMODEL_H

#include <QObject>
#include <QString>
#include "CoreBridge.h"

/// Qt object exposing a single session's details to QML.
/// Set the sessionId to track a specific session.
class SessionModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString sessionId READ sessionId WRITE setSessionId NOTIFY sessionIdChanged)
    Q_PROPERTY(QString name READ name NOTIFY updated)
    Q_PROPERTY(int state READ state NOTIFY updated)
    Q_PROPERTY(int provider READ provider NOTIFY updated)
    Q_PROPERTY(double cost READ cost NOTIFY updated)
    Q_PROPERTY(QString projectPath READ projectPath NOTIFY updated)
    Q_PROPERTY(QString output READ output NOTIFY updated)

public:
    explicit SessionModel(CoreBridge *bridge, QObject *parent = nullptr);

    QString sessionId() const { return m_sessionId; }
    void setSessionId(const QString &id);

    QString name() const;
    int state() const;
    int provider() const;
    double cost() const;
    QString projectPath() const;
    QString output() const;

    Q_INVOKABLE void sendInput(const QString &text);

signals:
    void sessionIdChanged();
    void updated();

private:
    CoreBridge *m_bridge;
    QString m_sessionId;

    ABSession currentSession() const;
};

#endif // SESSIONMODEL_H
