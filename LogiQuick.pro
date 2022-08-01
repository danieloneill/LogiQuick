QT += widgets
QT += opengl
QT += quick
QT += quickcontrols2
QT += webengine

CONFIG += c++17 console
CONFIG -= app_bundle

INCLUDEPATH += "Logitech LCD SDK/Include"
HEADERS += "Logitech LCD SDK/Include/LogitechLCDLib.h" \
    animationdriver.h \
    logiview.h
LIBS += "$${PWD}/Logitech LCD SDK/Lib/x64/LogitechLCDLib.lib"

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        animationdriver.cpp \
        logiview.cpp \
        main.cpp

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    media_test.qml \
    solarpv_test.qml \
    test.qml \
    web_test.qml
