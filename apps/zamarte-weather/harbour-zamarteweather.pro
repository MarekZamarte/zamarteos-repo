TEMPLATE = app
TARGET = harbour-zamarteweather
CONFIG += sailfishapp
QT += qml quick

SOURCES += src/harbour-zamarteweather.cpp
SAILFISHAPP_QML = qml/harbour-zamarteweather.qml

DISTFILES += \
    qml/harbour-zamarteweather.qml \
    qml/WeatherPage.qml \
    qml/cover.qml \
    desktop/harbour-zamarteweather.desktop \
    README_PL.md

target.path = /usr/bin
qmlfiles.files = qml/harbour-zamarteweather.qml qml/WeatherPage.qml qml/cover.qml
qmlfiles.path = /usr/share/harbour-zamarteweather/qml
desktop.files = desktop/harbour-zamarteweather.desktop
desktop.path = /usr/share/applications

INSTALLS += target qmlfiles desktop
