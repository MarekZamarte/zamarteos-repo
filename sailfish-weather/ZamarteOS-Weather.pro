TEMPLATE = app
TARGET = harbour-zamarteos-weather
CONFIG += sailfishapp
QT += qml quick network

SOURCES += src/harbour-zamarteos-weather.cpp

OTHER_FILES += \
    qml/main.qml \
    harbour-zamarteos-weather.desktop \
    icons/harbour-zamarteos-weather.svg \
    README.md

target.path = /usr/bin
qml.files = qml
qml.path = /usr/share/harbour-zamarteos-weather
desktop.files = harbour-zamarteos-weather.desktop
desktop.path = /usr/share/applications
icon.files = icons/harbour-zamarteos-weather.svg
icon.path = /usr/share/icons/hicolor/scalable/apps
INSTALLS += target qml desktop icon
