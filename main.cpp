#include <QApplication>
#include <QTimer>

#include <QtWebEngine>

#include "logiview.h"

// This is needed for some reason:
#pragma comment(lib,"advapi32.lib")

#include "LogitechLCDLib.h"

int main(int argc, char *argv[])
{
    QApplication::setAttribute(Qt::AA_ShareOpenGLContexts, true);
    QtWebEngine::initialize();
    QApplication a(argc, argv);

    LogiView *lv = new LogiView(QSize(LOGI_LCD_COLOR_WIDTH, LOGI_LCD_COLOR_HEIGHT), 30);
    lv->start();

    lv->loadQML(QUrl::fromLocalFile("../LogiQuick/test.qml"));

    QObject::connect( &a, &QCoreApplication::aboutToQuit, [lv](){
        emit lv->stop();
        lv->deleteLater();
    } );

    return a.exec();
}
