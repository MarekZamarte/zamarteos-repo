TEMPLATE = app
TARGET = harbour-zamarteos-home
CONFIG += sailfishapp
QT += qml quick

SOURCES += src/harbour-zamarteos-home.cpp

OTHER_FILES += \
    qml/main.qml \
    harbour-zamarteos-home.desktop \
    icons/harbour-zamarteos-home.svg \
    README.md

target.path = /usr/bin
desktop.files = harbour-zamarteos-home.desktop
desktop.path = /usr/share/applications
icon.files = icons/harbour-zamarteos-home.svg
icon.path = /usr/share/icons/hicolor/scalable/apps
INSTALLS += target desktop icon
