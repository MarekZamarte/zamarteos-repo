import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    id: app
    initialPage: Component {
        Page {
            id: home
            allowedOrientations: Orientation.Portrait
            property string statusText: "Gotowy"
            property string currentTime: Qt.formatTime(new Date(), "HH:mm")
            property string currentDate: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    home.currentTime = Qt.formatTime(new Date(), "HH:mm")
                    home.currentDate = Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                }
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: contentColumn.height + Theme.paddingLarge
                clip: true

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.paddingLarge

                    PageHeader {
                        title: "ZamarteOS"
                        description: "Panel dla Fairphone 4"
                    }

                    Rectangle {
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        height: 154
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: Theme.paddingLarge
                        color: "#142b3a"
                        border.color: "#267b83"
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.paddingLarge
                            spacing: Theme.paddingSmall

                            Label {
                                text: home.currentDate
                                color: "#a9c8ce"
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Label {
                                text: home.currentTime
                                color: "#ffffff"
                                font.pixelSize: Theme.fontSizeHuge
                            }
                            Label {
                                text: "Sailfish OS 5 • Fairphone 4"
                                color: "#a9c8ce"
                                font.pixelSize: Theme.fontSizeTiny
                            }
                        }
                    }

                    SectionHeader { text: "Szybki dostęp" }

                    Grid {
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 2
                        spacing: Theme.paddingMedium

                        Repeater {
                            model: [
                                { name: "Telefon", symbol: "☎", detail: "Połączenia", action: "tel:" },
                                { name: "Wiadomości", symbol: "✉", detail: "Nowy SMS", action: "sms:" },
                                { name: "Internet", symbol: "⌘", detail: "Przeglądarka", action: "https://example.com" },
                                { name: "Kontakty", symbol: "♙", detail: "Kontakty systemowe", action: "" },
                                { name: "Aparat", symbol: "◎", detail: "Zdjęcia", action: "" },
                                { name: "Ustawienia", symbol: "⚙", detail: "Ustawienia systemu", action: "" }
                            ]

                            delegate: BackgroundItem {
                                width: (parent.width - Theme.paddingMedium) / 2
                                height: 112

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

                                onClicked: {
                                    if (modelData.action !== "") {
                                        var ok = Qt.openUrlExternally(modelData.action)
                                        home.statusText = ok
                                            ? modelData.name + " — przekazano do systemu"
                                            : "Nie udało się otworzyć: " + modelData.name
                                    } else {
                                        home.statusText = modelData.name
                                            + " — integracja wymaga sprawdzenia na telefonie"
                                    }
                                }
                            }
                        }
                    }

                    SectionHeader { text: "Stan panelu" }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: home.statusText
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: "Panel działa jako osobna aplikacja. Nie zastępuje Lipstick i nie zmienia modemu, dźwięku rozmów ani usług telefonicznych."
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }
        }
    }
}
