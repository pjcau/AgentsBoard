#include "SessionModel.h"

SessionModel::SessionModel(CoreBridge *bridge, QObject *parent)
    : QObject(parent)
    , m_bridge(bridge)
{
    connect(bridge, &CoreBridge::fleetChanged, this, &SessionModel::updated);
}

void SessionModel::setSessionId(const QString &id)
{
    if (m_sessionId != id) {
        m_sessionId = id;
        emit sessionIdChanged();
        emit updated();
    }
}

ABSession SessionModel::currentSession() const
{
    if (m_sessionId.isEmpty()) return nullptr;
    return m_bridge->sessionById(m_sessionId);
}

QString SessionModel::name() const
{
    ABSession s = currentSession();
    if (!s) return {};
    const char *n = ab_session_get_name(s);
    return n ? QString::fromUtf8(n) : QString();
}

int SessionModel::state() const
{
    ABSession s = currentSession();
    return s ? ab_session_get_state(s) : AB_STATE_INACTIVE;
}

int SessionModel::provider() const
{
    ABSession s = currentSession();
    return s ? ab_session_get_provider(s) : AB_PROVIDER_CUSTOM;
}

double SessionModel::cost() const
{
    ABSession s = currentSession();
    return s ? ab_session_get_cost(s) : 0.0;
}

QString SessionModel::projectPath() const
{
    ABSession s = currentSession();
    if (!s) return {};
    const char *p = ab_session_get_project_path(s);
    return p ? QString::fromUtf8(p) : QString();
}

QString SessionModel::output() const
{
    ABSession s = currentSession();
    if (!s) return {};
    const char *o = ab_session_get_output(s);
    return o ? QString::fromUtf8(o) : QString();
}

void SessionModel::sendInput(const QString &text)
{
    if (!m_sessionId.isEmpty()) {
        m_bridge->sendInput(m_sessionId, text);
    }
}
