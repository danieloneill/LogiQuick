#include "systemtray.h"

#include <QMenu>
#include <QAction>

SystemTray::SystemTray(QObject *parent)
    : QSystemTrayIcon{parent}
{
    setIcon(QIcon(":/vgicon.png"));

    QMenu *menu = new QMenu();

    QAction *ainput = menu->addAction(tr("Toggle Input Window"));
    menu->addSeparator();
    QAction *aload = menu->addAction(tr("Load QML File"));
    QAction *amenu = menu->addAction(tr("Main Menu"));
    menu->addSeparator();
    QAction *aquit = menu->addAction(tr("Quit"));

    connect( ainput, &QAction::triggered, this, &SystemTray::inputwindow );
    connect( aload, &QAction::triggered, this, &SystemTray::load );
    connect( amenu, &QAction::triggered, this, &SystemTray::menu );
    connect( aquit, &QAction::triggered, this, &SystemTray::quit );

    setContextMenu(menu);

    connect( this, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if( reason != QSystemTrayIcon::Trigger )
            return;
        emit inputwindow();
    } );
}
