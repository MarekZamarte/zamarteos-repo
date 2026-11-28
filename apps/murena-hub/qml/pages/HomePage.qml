import QtQuick 2.0
import Sailfish.Silica 1.0
Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height
        VerticalScrollDecorator {}
        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingLarge
            PageHeader { title: "Murena Hub" }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.WordWrap
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                text: "Twoja prywatna chmura"
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.WordWrap
                text: "Otwórz Murena Workspace, aby korzystać ze zdjęć, plików, kontaktów, kalendarza, notatek, zadań i poczty. Zaloguj się w oknie Murena. Aplikacja nie prosi o hasło i go nie zapisuje."
            }
            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: "Połącz z Murena.io"
                onClicked: pageStack.push(Qt.resolvedUrl("CloudPage.qml"))
            }
            SectionHeader { text: "Usługi konta" }
            Repeater {
                model: ["Galeria / Photos", "Pliki / Drive", "Kontakty", "Kalendarz", "Notatki i zadania", "Poczta"]
                delegate: ListItem {
                    width: parent.width
                    contentHeight: Theme.itemSizeSmall
                    Label { x: Theme.horizontalPageMargin; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: Theme.primaryColor }
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: "Prototyp: usługi otwierają się w Sailfish WebView. Natywna galeria offline i synchronizacja będą osobnym etapem. Aplikacja nie jest oficjalnym produktem Murena."
            }
        }
    }
}
