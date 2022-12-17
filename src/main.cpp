#include <QApplication>
#include <QTimer>

#include <QSslSocket>

#include "logiview.h"
#include "systemtray.h"
#include "inputwindow.h"

#ifdef WIN32
// This is needed for some reason:
# pragma comment(lib,"advapi32.lib")
#endif

#include "g19device.hpp"

int main(int argc, char *argv[])
{
    QApplication::setAttribute(Qt::AA_ShareOpenGLContexts, true);

    QApplication a(argc, argv);
    a.setOrganizationName("oneill");
    a.setApplicationName("LogiQuick");
    a.setOrganizationDomain("oneill.app");
    a.setQuitOnLastWindowClosed(false);

    qDebug() << "SSL Support: " << QSslSocket::supportsSsl();

    SystemTray *st = new SystemTray(nullptr);
    st->show();

    LogiView *lv = new LogiView(QSize(LOGI_LCD_COLOR_WIDTH, LOGI_LCD_COLOR_HEIGHT), 30);
    lv->start();

    InputWindow *iw = new InputWindow(lv);
    //iw->show();

    QObject::connect( st, &SystemTray::inputwindow, [iw](){
        if( iw->isVisible() )
            iw->hide();
        else
        {
            iw->show();
            iw->raise();
        }
    } );
    QObject::connect( st, &SystemTray::quit, [](){ qApp->quit(); } );
    QObject::connect( st, &SystemTray::menu, [lv](){
        lv->loadQML(QUrl::fromLocalFile(":/menu.qml"));
    } );
    QObject::connect( st, &SystemTray::load, lv, &LogiView::showLoadDialogue );

    if( !lv->loadQML(QUrl::fromLocalFile(lv->settings()->value("lastFile", ":/menu.qml").toString())) )
    {
        qDebug() << "Couldn't load! Loading menu fallback instead:";
        lv->loadQML(QUrl::fromLocalFile(":/menu.qml"));
    }

    QObject::connect( &a, &QCoreApplication::aboutToQuit, [lv, st](){
        emit lv->stop();
        lv->deleteLater();

        st->hide();
        st->deleteLater();
    } );

    return a.exec();
}
