import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    id: app
    initialPage: Component { WeatherPage {} }
    cover: Qt.resolvedUrl("cover.qml")
}
