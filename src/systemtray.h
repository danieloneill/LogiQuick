#ifndef SYSTEMTRAY_H
#define SYSTEMTRAY_H

#include <QObject>
#include <QSystemTrayIcon>

class SystemTray : public QSystemTrayIcon
{
    Q_OBJECT

public:
    explicit SystemTray(QObject *parent = nullptr);

signals:
    void load();
    void inputwindow();
    void menu();
    void quit();
};

#endif // SYSTEMTRAY_H
