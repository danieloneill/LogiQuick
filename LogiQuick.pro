QT += widgets
QT += opengl
QT += quick
QT += quickcontrols2

# CONFIG += console
CONFIG += c++17
CONFIG -= app_bundle
CONFIG += link_pkgconfig

PKGCONFIG += libusb-1.0

HEADERS += \
    src/inputwindow.h \
    src/logiview.h \
    src/systemtray.h \
    src/g19device.hpp \
    src/hdata.hpp

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    src/inputwindow.cpp \
    src/logiview.cpp \
    src/main.cpp \
    src/systemtray.cpp \
    src/g19device.cpp

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    examples/examples.qml \
    examples/examples_media.qml \
    examples/examples_owncast.qml \
    examples/examples_solarpv.qml \
    examples/examples_web.qml \
    examples/menu.qml \
    examples/owncast.js \
    examples/qmldir \
    examples/ToonLabel.qml \
    examples/qtquickcontrols2.conf \
    examples/FPSCounter.qml

RESOURCES += \
    examples/resources.qrc
