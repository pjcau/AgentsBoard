#include "TerminalWidget.h"
#include <QKeyEvent>
#include <QMouseEvent>
#include <QFontMetricsF>
#include <QDebug>

#ifdef Q_OS_LINUX
#include <pty.h>
#include <unistd.h>
#include <sys/wait.h>
#include <signal.h>
#endif

QColor TerminalWidget::ansiColor(int c, bool b) {
    static const QColor n[]={{0,0,0},{0xCC,0,0},{0x4E,0x9A,0x06},{0xC4,0xA0,0},{0x34,0x65,0xA4},{0x75,0x50,0x7B},{0x06,0x98,0x9A},{0xD3,0xD7,0xCF}};
    static const QColor br[]={{0x55,0x57,0x53},{0xEF,0x29,0x29},{0x8A,0xE2,0x34},{0xFC,0xE9,0x4F},{0x72,0x9F,0xCF},{0xAD,0x7F,0xA8},{0x34,0xE2,0xE2},{0xEE,0xEE,0xEC}};
    if(c<0||c>7) return QColor("#E0E0E0");
    return b?br[c]:n[c];
}

QColor TerminalWidget::ansi256Color(int c) {
    if(c<8) return ansiColor(c,false);
    if(c<16) return ansiColor(c-8,true);
    if(c<232){int i=c-16; return QColor((i/36)*51,((i/6)%6)*51,(i%6)*51);}
    int g=8+(c-232)*10; return QColor(g,g,g);
}

TerminalWidget::TerminalWidget(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    setFlag(ItemAcceptsInputMethod,true);
    setFlag(ItemIsFocusScope,true);
    setAcceptedMouseButtons(Qt::AllButtons);
    setActiveFocusOnTab(true);

    m_font = QFont("Monospace",11);
    m_font.setStyleHint(QFont::Monospace);
    m_font.setFixedPitch(true);
    QFontMetricsF fm(m_font);
    m_cellW = fm.averageCharWidth();
    m_cellH = fm.height();
    if(m_cellW<4) m_cellW=8; if(m_cellH<8) m_cellH=16;

    // Init grid
    m_grid.resize(m_gridRows);
    for(auto &row:m_grid) row.resize(m_cols);
}

TerminalWidget::~TerminalWidget() {
    if(m_readNotifier){m_readNotifier->setEnabled(false);delete m_readNotifier;}
    if(m_childPid>0) kill(m_childPid,SIGTERM);
    if(m_masterFd>=0) close(m_masterFd);
}

void TerminalWidget::setBridge(QObject *b){m_bridge=qobject_cast<CoreBridge*>(b);}
void TerminalWidget::setSessionId(const QString &id){if(m_sessionId==id)return;m_sessionId=id;emit sessionIdChanged();}
void TerminalWidget::setCommand(const QString &cmd){
    if(m_command==cmd)return; m_command=cmd; emit commandChanged();
    if(!m_launched&&!cmd.isEmpty()&&m_cols>=40) launchProcess();
}
void TerminalWidget::setWorkingDirectory(const QString &d){if(m_workdir==d)return;m_workdir=d;emit workingDirectoryChanged();}

void TerminalWidget::launchProcess() {
    if(m_launched||m_command.isEmpty()) return;
#ifdef Q_OS_LINUX
    struct winsize ws={}; ws.ws_row=m_gridRows; ws.ws_col=m_cols;
    pid_t pid=forkpty(&m_masterFd,nullptr,nullptr,&ws);
    if(pid<0){qWarning()<<"forkpty failed";return;}
    if(pid==0){
        if(!m_workdir.isEmpty()) chdir(m_workdir.toUtf8().constData());
        setenv("TERM","xterm-256color",1);
        const char*home=getenv("HOME");
        const char*path=getenv("PATH");
        if(home&&path){char np[4096];snprintf(np,sizeof(np),"%s/.local/bin:%s/.cargo/bin:%s",home,home,path);setenv("PATH",np,1);}
        const char*sh=getenv("SHELL"); if(!sh) sh="/bin/bash";
        QByteArray cmd=m_command.toUtf8();
        execl(sh,sh,"-lc",cmd.constData(),nullptr);
        _exit(127);
    }
    m_childPid=pid; m_launched=true;
    m_readNotifier=new QSocketNotifier(m_masterFd,QSocketNotifier::Read,this);
    connect(m_readNotifier,&QSocketNotifier::activated,this,&TerminalWidget::onReadReady);
    qDebug()<<"TerminalWidget: launched"<<m_command<<"pid:"<<pid<<"size:"<<m_cols<<"x"<<m_gridRows;
#endif
}

void TerminalWidget::onReadReady() {
#ifdef Q_OS_LINUX
    char buf[4096]; ssize_t n=read(m_masterFd,buf,sizeof(buf));
    if(n>0) processOutput(QByteArray(buf,n));
    else if(n<=0){m_readNotifier->setEnabled(false);waitpid(m_childPid,nullptr,WNOHANG);m_childPid=-1;}
#endif
}

void TerminalWidget::mousePressEvent(QMouseEvent*e){forceActiveFocus();e->accept();}

void TerminalWidget::keyPressEvent(QKeyEvent *e) {
    if(m_masterFd<0){e->ignore();return;}
    QString t=e->text();
    if(t.isEmpty()){
        switch(e->key()){
        case Qt::Key_Return:case Qt::Key_Enter:t="\r";break;
        case Qt::Key_Backspace:t="\x7f";break;
        case Qt::Key_Tab:t="\t";break;
        case Qt::Key_Escape:t="\x1b";break;
        case Qt::Key_Up:t="\x1b[A";break; case Qt::Key_Down:t="\x1b[B";break;
        case Qt::Key_Right:t="\x1b[C";break; case Qt::Key_Left:t="\x1b[D";break;
        case Qt::Key_Home:t="\x1b[H";break; case Qt::Key_End:t="\x1b[F";break;
        case Qt::Key_Delete:t="\x1b[3~";break;
        case Qt::Key_PageUp:t="\x1b[5~";break; case Qt::Key_PageDown:t="\x1b[6~";break;
        default:e->ignore();return;
        }
    }
    if(e->modifiers()&Qt::ControlModifier&&t.length()==1){
        char c=t[0].toLatin1(); if(c>='a'&&c<='z') t=QString(QChar(c-'a'+1));
    }
    m_scrollOffset=0;
#ifdef Q_OS_LINUX
    QByteArray u=t.toUtf8(); ::write(m_masterFd,u.constData(),u.size());
#endif
    e->accept();
}

void TerminalWidget::wheelEvent(QWheelEvent *e) {
    int maxScroll=m_scrollback.size();
    if(e->angleDelta().y()>0) m_scrollOffset=qMin(m_scrollOffset+3,maxScroll);
    else m_scrollOffset=qMax(m_scrollOffset-3,0);
    update(); e->accept();
}

void TerminalWidget::paint(QPainter *p) {
    p->fillRect(0,0,width(),height(),QColor("#1A1A1A"));
    p->setFont(m_font);

    // Build display: scrollback + grid
    int totalVisible = m_gridRows;
    int sbStart = m_scrollback.size() - m_scrollOffset;

    for(int row=0; row<totalVisible; ++row) {
        qreal y = row * m_cellH;
        int srcRow = row - (totalVisible - m_gridRows); // map to grid row

        const QVector<Cell> *cells = nullptr;
        int sbIdx = sbStart + row - (totalVisible - m_gridRows);

        if (m_scrollOffset > 0 && row < m_scrollOffset && row < m_scrollback.size()) {
            // Show scrollback
            int idx = m_scrollback.size() - m_scrollOffset + row;
            if (idx >= 0 && idx < m_scrollback.size())
                cells = &m_scrollback[idx];
        }
        if (!cells && srcRow >= 0 && srcRow < m_gridRows) {
            cells = &m_grid[srcRow];
        }
        if (!cells) continue;

        for(int col=0; col<m_cols && col<cells->size(); ++col) {
            const Cell &c = (*cells)[col];
            if(c.bg!=Qt::transparent && c.bg.alpha()>0)
                p->fillRect(QRectF(col*m_cellW,y,m_cellW,m_cellH),c.bg);
            if(c.ch!=' ' && c.ch!='\0') {
                p->setPen(c.fg);
                p->drawText(QPointF(col*m_cellW, y+m_cellH-4), QString(c.ch));
            }
        }
    }

    // Cursor
    if(m_scrollOffset==0 && m_masterFd>=0 && m_curRow<m_gridRows && m_curCol<m_cols) {
        p->fillRect(QRectF(m_curCol*m_cellW, m_curRow*m_cellH, m_cellW, m_cellH),
                    QColor(255,255,255,128));
    }

    // Scrollbar
    int total=m_scrollback.size()+m_gridRows;
    if(total>m_gridRows){
        qreal bh=qMax(20.0,height()*m_gridRows/total);
        qreal by=height()*(1.0-(double)(m_scrollOffset+m_gridRows)/total);
        p->fillRect(QRectF(width()-4,by,3,bh),QColor(255,255,255,40));
    }
}

void TerminalWidget::geometryChange(const QRectF &n,const QRectF &o) {
    QQuickPaintedItem::geometryChange(n,o);
    recalculateSize();
}

void TerminalWidget::recalculateSize() {
    int nc=qMax(40,(int)(width()/m_cellW));
    int nr=qMax(10,(int)(height()/m_cellH));
    if(nc!=m_cols||nr!=m_gridRows) {
        int oldCols=m_cols, oldRows=m_gridRows;
        m_cols=nc; m_gridRows=nr;

        // Resize grid
        m_grid.resize(m_gridRows);
        for(auto &row:m_grid) row.resize(m_cols);

        // Clamp cursor
        if(m_curRow>=m_gridRows) m_curRow=m_gridRows-1;
        if(m_curCol>=m_cols) m_curCol=m_cols-1;

#ifdef Q_OS_LINUX
        if(m_masterFd>=0){
            struct winsize ws={}; ws.ws_row=m_gridRows; ws.ws_col=m_cols;
            ioctl(m_masterFd,TIOCSWINSZ,&ws);
        }
#endif
        if(!m_launched&&!m_command.isEmpty()&&m_cols>=40) launchProcess();
    }
}

void TerminalWidget::putChar(QChar ch) {
    if(m_curCol>=m_cols) { m_curCol=0; m_curRow++; }
    if(m_curRow>=m_gridRows) scrollUp();

    m_grid[m_curRow][m_curCol] = Cell{ch, m_fg, m_bg};
    m_curCol++;
}

void TerminalWidget::scrollUp() {
    // Move top line to scrollback
    m_scrollback.append(m_grid[0]);
    if(m_scrollback.size()>10000) m_scrollback.removeFirst();

    // Shift grid up
    for(int r=0;r<m_gridRows-1;++r) m_grid[r]=m_grid[r+1];
    m_grid[m_gridRows-1].fill(Cell{});

    m_curRow=m_gridRows-1;
}

void TerminalWidget::processSGR(const QString &params) {
    QStringList parts=params.split(';');
    bool bright=false;
    for(int i=0;i<parts.size();++i){
        int c=parts[i].isEmpty()?0:parts[i].toInt();
        if(c==0){m_fg=QColor("#E0E0E0");m_bg=Qt::transparent;bright=false;}
        else if(c==1) bright=true;
        else if(c==2||c==22) bright=false;
        else if(c==7){std::swap(m_fg,m_bg);if(m_bg==Qt::transparent)m_bg=QColor("#E0E0E0");if(m_fg==Qt::transparent)m_fg=QColor("#1A1A1A");}
        else if(c==27){std::swap(m_fg,m_bg);}
        else if(c>=30&&c<=37) m_fg=ansiColor(c-30,bright);
        else if(c>=40&&c<=47) m_bg=ansiColor(c-40,false);
        else if(c>=90&&c<=97) m_fg=ansiColor(c-90,true);
        else if(c>=100&&c<=107) m_bg=ansiColor(c-100,true);
        else if(c==39) m_fg=QColor("#E0E0E0");
        else if(c==49) m_bg=Qt::transparent;
        else if(c==38&&i+1<parts.size()){
            int m=parts[++i].toInt();
            if(m==5&&i+1<parts.size()) m_fg=ansi256Color(parts[++i].toInt());
            else if(m==2&&i+3<parts.size()){int r=parts[++i].toInt(),g=parts[++i].toInt(),b=parts[++i].toInt();m_fg=QColor(r,g,b);}
        }
        else if(c==48&&i+1<parts.size()){
            int m=parts[++i].toInt();
            if(m==5&&i+1<parts.size()) m_bg=ansi256Color(parts[++i].toInt());
            else if(m==2&&i+3<parts.size()){int r=parts[++i].toInt(),g=parts[++i].toInt(),b=parts[++i].toInt();m_bg=QColor(r,g,b);}
        }
    }
}

void TerminalWidget::processOutput(const QByteArray &data) {
    QString text=QString::fromUtf8(data);

    for(int i=0;i<text.length();++i){
        QChar ch=text[i];

        switch(m_parseState){
        case Normal:
            if(ch=='\x1b') m_parseState=Escape;
            else if(ch=='\n'){
                m_curRow++;
                if(m_curRow>=m_gridRows) scrollUp();
            }
            else if(ch=='\r') m_curCol=0;
            else if(ch=='\b'){if(m_curCol>0)m_curCol--;}
            else if(ch=='\t'){
                int sp=8-(m_curCol%8);
                for(int s=0;s<sp;++s) putChar(' ');
            }
            else if(ch=='\x07'){/* BEL */}
            else if(ch.isPrint()) putChar(ch);
            break;

        case Escape:
            if(ch=='['){m_parseState=CSI;m_csiParams.clear();}
            else if(ch==']') m_parseState=OSC;
            else if(ch=='(' || ch==')'){++i;m_parseState=Normal;} // charset select, skip next
            else if(ch=='M'){
                // Reverse index — scroll down
                if(m_curRow>0) m_curRow--;
                m_parseState=Normal;
            }
            else if(ch=='7'||ch=='8') m_parseState=Normal; // save/restore cursor — ignore
            else if(ch=='='){m_parseState=Normal;} // keypad mode
            else if(ch=='>'){m_parseState=Normal;} // keypad mode
            else m_parseState=Normal;
            break;

        case CSI:
            if((ch>='0'&&ch<='9')||ch==';'||ch=='?'||ch==':'||ch=='>'||ch=='!') {
                m_csiParams.append(ch);
            } else {
                // Execute CSI command
                int n1=1; // default param
                QStringList pp=m_csiParams.split(';');
                if(!pp.isEmpty()&&!pp[0].isEmpty()) n1=pp[0].toInt();

                if(ch=='m') processSGR(m_csiParams);
                else if(ch=='A'){m_curRow=qMax(0,m_curRow-qMax(1,n1));} // Cursor Up
                else if(ch=='B'){m_curRow=qMin(m_gridRows-1,m_curRow+qMax(1,n1));} // Cursor Down
                else if(ch=='C'){m_curCol=qMin(m_cols-1,m_curCol+qMax(1,n1));} // Cursor Forward
                else if(ch=='D'){m_curCol=qMax(0,m_curCol-qMax(1,n1));} // Cursor Back
                else if(ch=='G'||ch=='`'){m_curCol=qMax(0,qMin(m_cols-1,n1-1));} // Cursor Horizontal Absolute
                else if(ch=='H'||ch=='f'){ // Cursor Position
                    int r=1,c=1;
                    if(pp.size()>=1&&!pp[0].isEmpty()) r=pp[0].toInt();
                    if(pp.size()>=2&&!pp[1].isEmpty()) c=pp[1].toInt();
                    m_curRow=qMax(0,qMin(m_gridRows-1,r-1));
                    m_curCol=qMax(0,qMin(m_cols-1,c-1));
                }
                else if(ch=='J'){ // Erase Display
                    int mode=m_csiParams.isEmpty()?0:m_csiParams.toInt();
                    if(mode==0){
                        for(int c=m_curCol;c<m_cols;++c) m_grid[m_curRow][c]=Cell{};
                        for(int r=m_curRow+1;r<m_gridRows;++r) m_grid[r].fill(Cell{});
                    } else if(mode==1){
                        for(int r=0;r<m_curRow;++r) m_grid[r].fill(Cell{});
                        for(int c=0;c<=m_curCol;++c) m_grid[m_curRow][c]=Cell{};
                    } else if(mode==2||mode==3){
                        for(auto &r:m_grid) r.fill(Cell{});
                        m_curRow=0;m_curCol=0;
                    }
                }
                else if(ch=='K'){ // Erase in Line
                    int mode=m_csiParams.isEmpty()?0:m_csiParams.toInt();
                    if(mode==0){for(int c=m_curCol;c<m_cols;++c) m_grid[m_curRow][c]=Cell{};}
                    else if(mode==1){for(int c=0;c<=m_curCol;++c) m_grid[m_curRow][c]=Cell{};}
                    else if(mode==2) m_grid[m_curRow].fill(Cell{});
                }
                else if(ch=='L'){ // Insert Lines
                    int n=qMax(1,n1);
                    for(int j=0;j<n&&m_curRow<m_gridRows;++j){
                        m_grid.insert(m_curRow,QVector<Cell>(m_cols));
                        if(m_grid.size()>m_gridRows) m_grid.removeLast();
                    }
                }
                else if(ch=='M'){ // Delete Lines
                    int n=qMax(1,n1);
                    for(int j=0;j<n&&m_curRow<m_gridRows;++j){
                        m_grid.removeAt(m_curRow);
                        m_grid.append(QVector<Cell>(m_cols));
                    }
                }
                else if(ch=='P'){ // Delete Characters
                    int n=qMax(1,n1);
                    for(int j=0;j<n&&m_curCol+j<m_cols;++j){
                        m_grid[m_curRow].remove(m_curCol,1);
                        m_grid[m_curRow].append(Cell{});
                    }
                }
                else if(ch=='@'){ // Insert Characters
                    int n=qMax(1,n1);
                    for(int j=0;j<n;++j){
                        m_grid[m_curRow].insert(m_curCol,Cell{});
                        if(m_grid[m_curRow].size()>m_cols) m_grid[m_curRow].removeLast();
                    }
                }
                else if(ch=='d'){m_curRow=qMax(0,qMin(m_gridRows-1,n1-1));} // VPA
                else if(ch=='n'){ // Device Status Report
                    if(m_csiParams=="6"&&m_masterFd>=0){
                        char r[32];snprintf(r,sizeof(r),"\x1b[%d;%dR",m_curRow+1,m_curCol+1);
                        ::write(m_masterFd,r,strlen(r));
                    }
                }
                else if(ch=='r'){ /* scroll region — ignore for now */ }
                else if(ch=='h'||ch=='l'){ /* DEC private modes — ignore */ }
                else if(ch=='S'){ // Scroll Up
                    int n=qMax(1,n1);
                    for(int j=0;j<n;++j) scrollUp();
                }
                else if(ch=='T'){ // Scroll Down
                    int n=qMax(1,n1);
                    for(int j=0;j<n;++j){
                        m_grid.insert(0,QVector<Cell>(m_cols));
                        if(m_grid.size()>m_gridRows) m_grid.removeLast();
                    }
                }
                m_parseState=Normal;
            }
            break;

        case OSC:
            if(ch=='\x07') m_parseState=Normal;
            else if(ch=='\x1b'&&i+1<text.length()&&text[i+1]=='\\'){++i;m_parseState=Normal;}
            break;
        }
    }
    update();
}
