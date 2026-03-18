#include "CoreBridge.h"
#include <QDebug>

CoreBridge::CoreBridge(QObject *parent)
    : QObject(parent)
{
    m_core = ab_core_create();
    if (!m_core) {
        qWarning("CoreBridge: ab_core_create() returned NULL");
        return;
    }

    // Register fleet callback
    ab_fleet_set_callback(m_core, &CoreBridge::fleetCallbackTrampoline, this);

    // Initial stats fetch
    refreshStats();

    qDebug() << "CoreBridge initialized — version:" << version();
}

CoreBridge::~CoreBridge()
{
    if (m_core) {
        ab_fleet_set_callback(m_core, nullptr, nullptr);
        ab_core_destroy(m_core);
        m_core = nullptr;
    }
}

void CoreBridge::refreshStats()
{
    if (!m_core) return;
    ab_fleet_get_stats(m_core, m_stats, &m_totalCost);
}

int CoreBridge::sessionCount() const { return m_stats[0]; }
double CoreBridge::totalCost() const { return m_totalCost; }
int CoreBridge::activeCount() const { return m_stats[1]; }
int CoreBridge::needsInputCount() const { return m_stats[2]; }
int CoreBridge::errorCount() const { return m_stats[3]; }

QString CoreBridge::version() const
{
    const char *v = ab_version();
    return v ? QString::fromUtf8(v) : QStringLiteral("unknown");
}

ABSession CoreBridge::sessionAt(int index) const
{
    if (!m_core) return nullptr;
    return ab_fleet_get_session(m_core, index);
}

ABSession CoreBridge::sessionById(const QString &id) const
{
    if (!m_core) return nullptr;
    QByteArray utf8 = id.toUtf8();
    return ab_fleet_get_session_by_id(m_core, utf8.constData());
}

QString CoreBridge::createSession(const QString &command,
                                   const QString &name,
                                   const QString &workdir)
{
    if (!m_core) return {};

    QByteArray cmdUtf8 = command.toUtf8();
    QByteArray nameUtf8 = name.toUtf8();
    QByteArray wdUtf8 = workdir.toUtf8();

    ABSession session = ab_session_create(
        m_core,
        cmdUtf8.constData(),
        nameUtf8.constData(),
        workdir.isEmpty() ? nullptr : wdUtf8.constData()
    );

    if (!session) return {};

    const char *id = ab_session_get_id(session);
    return id ? QString::fromUtf8(id) : QString();
}

void CoreBridge::sendInput(const QString &sessionId, const QString &text)
{
    ABSession session = sessionById(sessionId);
    if (!session) return;
    QByteArray utf8 = text.toUtf8();
    ab_session_send_input(session, utf8.constData(), utf8.size());
}

void CoreBridge::archiveSession(const QString &sessionId)
{
    if (!m_core) return;
    QByteArray utf8 = sessionId.toUtf8();
    ab_session_archive(m_core, utf8.constData());
}

void CoreBridge::deleteSession(const QString &sessionId)
{
    if (!m_core) return;
    QByteArray utf8 = sessionId.toUtf8();
    ab_session_delete(m_core, utf8.constData());
}

bool CoreBridge::loadConfig(const QString &path)
{
    if (!m_core) return false;
    QByteArray utf8 = path.toUtf8();
    return ab_config_load(m_core, utf8.constData());
}

int CoreBridge::layout() const
{
    if (!m_core) return AB_LAYOUT_FLEET;
    return ab_config_get_layout(m_core);
}

void CoreBridge::setLayout(int mode)
{
    if (!m_core) return;
    ab_config_set_layout(m_core, mode);
}

double CoreBridge::fontSize() const
{
    if (!m_core) return 13.0;
    return ab_config_get_font_size(m_core);
}

void CoreBridge::setFontSize(double size)
{
    if (!m_core) return;
    ab_config_set_font_size(m_core, size);
}

void CoreBridge::fleetCallbackTrampoline(int32_t eventType, void *context)
{
    auto *self = static_cast<CoreBridge *>(context);
    if (!self) return;

    // Refresh cached stats and notify QML
    self->refreshStats();
    emit self->fleetChanged();
}
