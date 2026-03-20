#ifndef TERMINALWIDGET_H
#define TERMINALWIDGET_H

#include <QQuickPaintedItem>
#include <QPainter>
#include <QSocketNotifier>
#include "CoreBridge.h"

class TerminalWidget : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QString sessionId READ sessionId WRITE setSessionId NOTIFY sessionIdChanged)
    Q_PROPERTY(QString command READ command WRITE setCommand NOTIFY commandChanged)
    Q_PROPERTY(QString workingDirectory READ workingDirectory WRITE setWorkingDirectory NOTIFY workingDirectoryChanged)

public:
    explicit TerminalWidget(QQuickItem *parent = nullptr);
    ~TerminalWidget() override;

    QString sessionId() const { return m_sessionId; }
    void setSessionId(const QString &id);
    QString command() const { return m_command; }
    void setCommand(const QString &cmd);
    QString workingDirectory() const { return m_workdir; }
    void setWorkingDirectory(const QString &dir);

    void paint(QPainter *painter) override;

    Q_INVOKABLE void setBridge(QObject *bridge);
    Q_INVOKABLE void launchProcess();

signals:
    void sessionIdChanged();
    void commandChanged();
    void workingDirectoryChanged();

protected:
    void mousePressEvent(QMouseEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private slots:
    void onReadReady();

private:
    void recalculateSize();
    void processOutput(const QByteArray &data);

    CoreBridge *m_bridge = nullptr;
    QString m_sessionId, m_command, m_workdir;

    // PTY
    int m_masterFd = -1;
    pid_t m_childPid = -1;
    QSocketNotifier *m_readNotifier = nullptr;
    bool m_launched = false;

    // VT100 grid
    struct Cell { QChar ch = ' '; QColor fg = QColor("#E0E0E0"); QColor bg = Qt::transparent; };
    int m_cols = 80, m_gridRows = 24;
    int m_curRow = 0, m_curCol = 0;
    QVector<QVector<Cell>> m_grid;        // visible screen grid
    QVector<QVector<Cell>> m_scrollback;  // scrolled-off lines
    int m_scrollOffset = 0;

    // Current style
    QColor m_fg = QColor("#E0E0E0");
    QColor m_bg = Qt::transparent;

    // Font
    QFont m_font;
    qreal m_cellW = 8.0, m_cellH = 16.0;

    // ANSI
    enum ParseState { Normal, Escape, CSI, OSC };
    ParseState m_parseState = Normal;
    QString m_csiParams;

    void putChar(QChar ch);
    void scrollUp();
    void processSGR(const QString &params);

    static QColor ansiColor(int code, bool bright);
    static QColor ansi256Color(int code);
};

#endif
