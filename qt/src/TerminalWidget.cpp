#include "TerminalWidget.h"
#include <QKeyEvent>
#include <QFontMetricsF>
#include <QDebug>

TerminalWidget::TerminalWidget(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setFlag(ItemAcceptsInputMethod, true);
    setAcceptedMouseButtons(Qt::AllButtons);
    setFocus(true);

    // Monospace font
    m_font = QFont("Monospace", 12);
    m_font.setStyleHint(QFont::Monospace);

    QFontMetricsF fm(m_font);
    m_cellWidth = fm.horizontalAdvance('M');
    m_cellHeight = fm.height();

    // Initialize with empty content
    m_lines.append("");
}

TerminalWidget::~TerminalWidget()
{
    if (m_session) {
        ab_terminal_set_callbacks(m_session, nullptr, nullptr, nullptr);
    }
}

void TerminalWidget::setBridge(QObject *bridge)
{
    m_bridge = qobject_cast<CoreBridge *>(bridge);
}

void TerminalWidget::setSessionId(const QString &id)
{
    if (m_sessionId == id) return;

    // Unregister old callbacks
    if (m_session) {
        ab_terminal_set_callbacks(m_session, nullptr, nullptr, nullptr);
    }

    m_sessionId = id;
    m_session = nullptr;
    m_lines.clear();
    m_lines.append("");

    if (m_bridge && !id.isEmpty()) {
        m_session = m_bridge->sessionById(id);
        if (m_session) {
            // Register callbacks
            ab_terminal_set_callbacks(m_session,
                                      &TerminalWidget::dataTrampoline,
                                      &TerminalWidget::exitTrampoline,
                                      this);

            // Load existing output
            const char *output = ab_session_get_output(m_session);
            if (output) {
                appendOutput(QByteArray(output));
            }
        }
    }

    emit sessionIdChanged();
    update();
}

void TerminalWidget::paint(QPainter *painter)
{
    // Background
    painter->fillRect(0, 0, width(), height(), QColor("#1A1A1A"));

    painter->setFont(m_font);

    int visibleRows = qMin(m_rows, m_lines.size());
    int startLine = qMax(0, m_lines.size() - visibleRows - m_scrollOffset);

    for (int row = 0; row < visibleRows && (startLine + row) < m_lines.size(); ++row) {
        const QString &line = m_lines[startLine + row];

        // Simple rendering: white text on dark background
        painter->setPen(QColor("#E0E0E0"));
        qreal y = (row + 1) * m_cellHeight;
        painter->drawText(QPointF(2, y - 3), line.left(m_columns));
    }

    // Cursor (blinking block at end of last line)
    if (!m_lines.isEmpty()) {
        int cursorRow = qMin(visibleRows - 1, m_lines.size() - 1 - startLine);
        int cursorCol = m_lines.last().length();
        if (cursorRow >= 0 && cursorCol < m_columns) {
            painter->fillRect(
                QRectF(cursorCol * m_cellWidth + 2, cursorRow * m_cellHeight,
                       m_cellWidth, m_cellHeight),
                QColor(255, 255, 255, 128)
            );
        }
    }
}

void TerminalWidget::keyPressEvent(QKeyEvent *event)
{
    if (!m_session) return;

    QString text = event->text();
    if (text.isEmpty()) {
        // Handle special keys
        switch (event->key()) {
        case Qt::Key_Return:
        case Qt::Key_Enter:
            text = "\r";
            break;
        case Qt::Key_Backspace:
            text = "\x7f";
            break;
        case Qt::Key_Tab:
            text = "\t";
            break;
        case Qt::Key_Escape:
            text = "\x1b";
            break;
        case Qt::Key_Up:    text = "\x1b[A"; break;
        case Qt::Key_Down:  text = "\x1b[B"; break;
        case Qt::Key_Right: text = "\x1b[C"; break;
        case Qt::Key_Left:  text = "\x1b[D"; break;
        default:
            event->ignore();
            return;
        }
    }

    // Handle Ctrl+key
    if (event->modifiers() & Qt::ControlModifier && text.length() == 1) {
        char ch = text[0].toLatin1();
        if (ch >= 'a' && ch <= 'z') {
            char ctrl = ch - 'a' + 1;
            text = QString(QChar(ctrl));
        }
    }

    QByteArray utf8 = text.toUtf8();
    ab_session_send_input(m_session, utf8.constData(), utf8.size());
}

void TerminalWidget::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    recalculateSize();
}

void TerminalWidget::recalculateSize()
{
    int newCols = qMax(1, static_cast<int>(width() / m_cellWidth));
    int newRows = qMax(1, static_cast<int>(height() / m_cellHeight));

    if (newCols != m_columns || newRows != m_rows) {
        m_columns = newCols;
        m_rows = newRows;

        if (m_session) {
            ab_terminal_resize(m_session, m_columns, m_rows);
        }

        emit sizeChanged();
    }
}

void TerminalWidget::appendOutput(const QByteArray &data)
{
    QString text = QString::fromUtf8(data);

    for (const QChar &ch : text) {
        if (ch == '\n') {
            m_lines.append("");
        } else if (ch == '\r') {
            // Carriage return — overwrite current line
            if (!m_lines.isEmpty()) {
                m_lines.last().clear();
            }
        } else if (ch.isPrint() || ch == '\t') {
            if (m_lines.isEmpty()) m_lines.append("");
            m_lines.last().append(ch);
        }
        // Skip other control characters
    }

    // Limit scrollback
    const int maxLines = 10000;
    while (m_lines.size() > maxLines) {
        m_lines.removeFirst();
    }

    update();
    emit outputReceived(text);
}

void TerminalWidget::dataTrampoline(const char *sessionId, const uint8_t *data,
                                     int32_t len, void *context)
{
    auto *self = static_cast<TerminalWidget *>(context);
    if (!self || !data || len <= 0) return;

    QByteArray bytes(reinterpret_cast<const char *>(data), len);

    // Marshal to main thread
    QMetaObject::invokeMethod(self, [self, bytes]() {
        self->appendOutput(bytes);
    }, Qt::QueuedConnection);
}

void TerminalWidget::exitTrampoline(const char *sessionId, int32_t exitCode,
                                     void *context)
{
    auto *self = static_cast<TerminalWidget *>(context);
    if (!self) return;

    QMetaObject::invokeMethod(self, [self, exitCode]() {
        self->appendOutput(QByteArray("\r\n[Process exited with code ")
                           + QByteArray::number(exitCode) + "]\r\n");
    }, Qt::QueuedConnection);
}
