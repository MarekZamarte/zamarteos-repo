import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    id: app
    initialPage: Component {
        Page {
            id: home
            allowedOrientations: Orientation.Portrait

            property string notice: "ZamarteOS — ekran startowy"

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: contentColumn.height + Theme.paddingLarge

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.paddingLarge

                    PageHeader {
                        title: "ZamarteOS"
                        description: "Fairphone 4 • Sailfish OS"
                    }

                    Rectangle {
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        height: 112
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: Theme.paddingMedium
                        color: "#142b3a"
                        border.color: "#267b83"
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.paddingLarge
                            spacing: Theme.paddingSmall

                            Label {
                                text: Qt.formatDate(new Date(), "dddd, d MMMM")
                                color: "#a9c8ce"
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Label {
                                text: Qt.formatTime(new Date(), "HH:mm")
                                color: "#ffffff"
                                font.pixelSize: Theme.fontSizeHuge
                            }
                            Label {
                                text: "System bazowy Sailfish OS"
                                color: "#a9c8ce"
                                font.pixelSize: Theme.fontSizeTiny
                            }
                        }
                    }

                    SectionHeader {
                        text: "Aplikacje"
                    }

                    Grid {
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 2
                        spacing: Theme.paddingMedium

                        Repeater {
                            model: [
                                { name: "Telefon", symbol: "☎", detail: "Połączenia" },
                                { name: "Wiadomości", symbol: "✉", detail: "SMS" },
                                { name: "Kontakty", symbol: "♙", detail: "Osoby" },
                                { name: "Aparat", symbol: "◎", detail: "Zdjęcia" },
                                { name: "Internet", symbol: "⌘", detail: "Przeglądarka" },
                                { name: "Ustawienia", symbol: "⚙", detail: "System" }
                            ]

                            delegate: BackgroundItem {
                                width: (parent.width - Theme.paddingMedium) / 2
                                height: 104
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.paddingMedium
                                    color: highlighted ? "#24505b" : "#182d3b"
                                    border.color: "#315b68"
                                    border.width: 1
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.paddingSmall
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.symbol
                                        color: "#63c4c0"
                                        font.pixelSize: Theme.fontSizeExtraLarge
                                    }
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.name
                                        color: "#ffffff"
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.detail
                                        color: "#a9c8ce"
                                        font.pixelSize: Theme.fontSizeTiny
                                    }
                                }
                                onClicked: home.notice = modelData.name + " — skrót zostanie podłączony po testach"
                            }
                        }
                    }

                    SectionHeader {
                        text: "Informacja"
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: home.notice
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: "To niezależna aplikacja testowa. Nie zastępuje ekranu systemowego i nie zmienia obsługi połączeń ani dźwięku."
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }
        }
    }
}
