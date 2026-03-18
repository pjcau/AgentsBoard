#ifndef TERMINALWIDGET_H
#define TERMINALWIDGET_H

#include <QQuickPaintedItem>
#include <QPainter>
#include <QTimer>
#include "CoreBridge.h"

/// Terminal rendering widget for QML.
/// Receives PTY output via C FFI callbacks and renders a character grid.
/// Keyboard input is forwarded to the session via ab_session_send_input.
class TerminalWidget : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QString sessionId READ sessionId WRITE setSessionId NOTIFY sessionIdChanged)
    Q_PROPERTY(int columns READ columns NOTIFY sizeChanged)
    Q_PROPERTY(int rows READ rows NOTIFY sizeChanged)

public:
    explicit TerminalWidget(QQuickItem *parent = nullptr);
    ~TerminalWidget() override;

    QString sessionId() const { return m_sessionId; }
    void setSessionId(const QString &id);

    int columns() const { return m_columns; }
    int rows() const { return m_rows; }

    void paint(QPainter *painter) override;

    // Set the CoreBridge (called from QML context setup)
    Q_INVOKABLE void setBridge(QObject *bridge);

signals:
    void sessionIdChanged();
    void sizeChanged();
    void outputReceived(const QString &text);

protected:
    void keyPressEvent(QKeyEvent *event) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void recalculateSize();
    void appendOutput(const QByteArray &data);

    CoreBridge *m_bridge = nullptr;
    QString m_sessionId;
    ABSession m_session = nullptr;

    // Terminal grid
    int m_columns = 80;
    int m_rows = 24;
    qreal m_cellWidth = 8.0;
    qreal m_cellHeight = 16.0;

    // Output buffer (raw text for rendering)
    QStringList m_lines;
    int m_scrollOffset = 0;

    // Font
    QFont m_font;

    // Callback trampolines
    static void dataTrampoline(const char *sessionId, const uint8_t *data,
                                int32_t len, void *context);
    static void exitTrampoline(const char *sessionId, int32_t exitCode,
                                void *context);
};

#endif // TERMINALWIDGET_H
