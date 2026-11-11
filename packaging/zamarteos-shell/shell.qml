pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root
    property var now: new Date()
    property bool drawerOpen: false
    property bool controlOpen: false
    property string searchText: ""
    property string notice: ""
    property string lockInput: ""
    property string lockError: ""

    function showNotice(message) {
        notice = message
        noticeTimer.restart()
    }

    function authenticateLock() {
        if (lockInput.length === 0 || pam.active)
            return
        lockError = ""
        if (!pam.start())
            lockError = "Nie można uruchomić uwierzytelniania"
    }

    // Hide only vendor-branded launcher entries. Keep hardware services,
    // drivers and their packages installed; this is a presentation-layer filter.
    function isVisibleApp(entry) {
        const id = String(entry.id || "").toLowerCase()
        const name = String(entry.name || "").toLowerCase()
        const genericName = String(entry.genericName || "").toLowerCase()
        return id.indexOf("moarchy") === -1 && id.indexOf("omarchy") === -1 &&
               name.indexOf("moarchy") === -1 && name.indexOf("omarchy") === -1 &&
               genericName.indexOf("moarchy") === -1 && genericName.indexOf("omarchy") === -1
    }

    function launchByKeywords(keywords, label) {
        const entries = DesktopEntries.applications.values
        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            if (!isVisibleApp(entry))
                continue
            const haystack = ((entry.name || "") + " " + (entry.genericName || "") + " " + (entry.id || "")).toLowerCase()
            for (let j = 0; j < keywords.length; ++j) {
                if (haystack.indexOf(keywords[j]) !== -1) {
                    entry.execute()
                    drawerOpen = false
                    controlOpen = false
                    return true
                }
            }
        }
        showNotice(label + ": nie znaleziono zainstalowanej aplikacji.")
        return false
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    Timer {
        id: noticeTimer
        interval: 3200
        onTriggered: root.notice = ""
    }

    IpcHandler {
        target: "zamarteos-lock"
        function lock(): void {
            root.lockInput = ""
            root.lockError = ""
            sessionLock.locked = true
        }
    }

    PamContext {
        id: pam
        config: "zamarteos-lock"
        onPamMessage: {
            if (responseRequired)
                respond(root.lockInput)
        }
        onCompleted: result => {
            const success = result === PamResult.Success
            root.lockInput = ""
            root.lockError = success ? "" : "Kod nieprawidłowy"
            if (success)
                sessionLock.locked = false
        }
    }

    WlSessionLock {
        id: sessionLock
        WlSessionLockSurface {
            color: "#0b111b"
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#142235" }
                    GradientStop { position: 1.0; color: "#0b111b" }
                }
                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 48, 340)
                    spacing: 18
                    Text {
                        width: parent.width
                        text: "ZAMARTEOS"
                        color: "#d7f0e6"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.letterSpacing: 3
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: Qt.formatDateTime(root.now, "HH:mm")
                        color: "#ffffff"
                        font.pixelSize: 62
                        font.weight: Font.Light
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: Qt.formatDateTime(root.now, "dddd, d MMMM")
                        color: "#a9bdcf"
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: "Wprowadź kod telefonu"
                        color: "#eaf0f5"
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: "● ".repeat(root.lockInput.length)
                        color: "#d7f0e6"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Grid {
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 3
                        spacing: 12
                        Repeater {
                            model: ["1","2","3","4","5","6","7","8","9","⌫","0","↵"]
                            delegate: Rectangle {
                                id: digitDelegate
                                required property string modelData
                                width: 82
                                height: 62
                                radius: 20
                                color: "#26394d"
                                border.width: 1
                                border.color: "#3a526b"
                                Text {
                                    anchors.centerIn: parent
                                    text: digitDelegate.modelData
                                    color: "#ffffff"
                                    font.pixelSize: 22
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (digitDelegate.modelData === "⌫") {
                                            root.lockInput = root.lockInput.slice(0, -1)
                                            root.lockError = ""
                                        } else if (digitDelegate.modelData === "↵") {
                                            root.authenticateLock()
                                        } else if (root.lockInput.length < 32) {
                                            root.lockInput += digitDelegate.modelData
                                            root.lockError = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        text: root.lockError
                        color: "#ff9a9a"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: pam.active ? "Sprawdzanie…" : "Odblokowanie chronione przez PAM"
                        color: "#8095a9"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        aboveWindows: root.drawerOpen || root.controlOpen
        exclusiveZone: 0
        focusable: root.drawerOpen || root.controlOpen
        color: "#0b111b"

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#142235" }
                GradientStop { position: 0.55; color: "#0b111b" }
                GradientStop { position: 1.0; color: "#101b29" }
            }
        }

        Flickable {
            id: homeScroll
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            anchors.topMargin: 26
            anchors.bottomMargin: 28
            clip: true
            contentWidth: width
            contentHeight: homeColumn.implicitHeight

            Column {
                id: homeColumn
                width: homeScroll.width
                spacing: 22

                Row {
                    width: parent.width
                    height: 62
                    spacing: 14

                    Rectangle {
                        width: 54; height: 54; radius: 18
                        color: "#d7f0e6"
                        Text {
                            anchors.centerIn: parent
                            text: "Z"; color: "#122b2b"
                            font.pixelSize: 32; font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        width: Math.max(100, parent.width - 152)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "ZAMARTEOS"; color: "#f3f6fa"
                            font.pixelSize: 20; font.weight: Font.Bold
                            font.letterSpacing: 2
                        }
                        Text {
                            text: "PURE  •  FAIRPHONE 4"; color: "#91a4ba"
                            font.pixelSize: 11; font.letterSpacing: 1.5
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            text: Qt.formatDateTime(root.now, "HH:mm")
                            color: "#f3f6fa"; font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: Qt.formatDateTime(root.now, "ddd, d MMM")
                            color: "#91a4ba"; font.pixelSize: 12
                        }
                    }
                }

                Rectangle {
                    width: parent.width; height: 244; radius: 30
                    color: "#1c3045"; border.width: 1; border.color: "#35516b"
                    Rectangle {
                        width: 150; height: 150; radius: 75
                        color: "#284d5a"; opacity: 0.55
                        anchors.right: parent.right; anchors.top: parent.top
                        anchors.rightMargin: 24; anchors.topMargin: 22
                    }
                    Column {
                        anchors.left: parent.left; anchors.bottom: parent.bottom
                        anchors.leftMargin: 28; anchors.bottomMargin: 26
                        spacing: 7
                        Text { text: "Twoje centrum telefonu"; color: "#b5c9d8"; font.pixelSize: 15 }
                        Text {
                            text: Qt.formatDateTime(root.now, "HH:mm")
                            color: "#ffffff"; font.pixelSize: 76; font.weight: Font.Light
                        }
                        Text {
                            text: Qt.formatDateTime(root.now, "dddd, d MMMM")
                            color: "#c0d1df"; font.pixelSize: 17
                        }
                    }
                }

                Text {
                    text: "SZYBKIE URUCHAMIANIE"; color: "#8ea4ba"
                    font.pixelSize: 12; font.weight: Font.DemiBold; font.letterSpacing: 1.8
                }

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 14
                    Repeater {
                        model: [
                            { title: "Telefon", subtitle: "Połączenia i kontakty", symbol: "☎", words: ["phone", "calls", "telefon"] },
                            { title: "Wiadomości", subtitle: "SMS i rozmowy", symbol: "✉", words: ["messages", "chatty", "sms", "messaging"] },
                            { title: "Aparat", subtitle: "Zdjęcia", symbol: "◎", words: ["camera", "megapixels", "aparat"] },
                            { title: "Pliki", subtitle: "Pamięć telefonu", symbol: "▤", words: ["files", "file manager", "pliki"] }
                        ]
                        delegate: Rectangle {
                            id: appDelegate
                            required property var modelData
                            width: (homeColumn.width - 14) / 2
                            height: 126; radius: 22
                            color: "#18283a"; border.width: 1; border.color: "#2c435a"
                            Column {
                                anchors.fill: parent; anchors.margins: 17; spacing: 7
                                Text { text: appDelegate.modelData.symbol; color: "#a9d7c9"; font.pixelSize: 27 }
                                Text {
                                    text: appDelegate.modelData.title; color: "#f0f4f8"
                                    font.pixelSize: 17; font.weight: Font.DemiBold
                                }
                                Text { text: appDelegate.modelData.subtitle; color: "#91a4ba"; font.pixelSize: 11 }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.launchByKeywords(appDelegate.modelData.words, appDelegate.modelData.title)
                            }
                        }
                    }
                }

                Row {
                    width: parent.width; spacing: 12
                    Rectangle {
                        width: (parent.width - 12) / 2; height: 64; radius: 20
                        color: "#d7f0e6"
                        Text {
                            anchors.centerIn: parent
                            text: "▦   Wszystkie aplikacje"
                            color: "#142b2b"; font.pixelSize: 15; font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.searchText = ""; root.drawerOpen = true }
                        }
                    }
                    Rectangle {
                        width: (parent.width - 12) / 2; height: 64; radius: 20
                        color: "#26394d"; border.width: 1; border.color: "#3a526b"
                        Text {
                            anchors.centerIn: parent
                            text: "☷   Centrum telefonu"
                            color: "#edf3f8"; font.pixelSize: 15; font.weight: Font.DemiBold
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.controlOpen = true }
                    }
                }

                Text {
                    width: parent.width
                    text: "ZamarteOS Pure  •  Wersja rozwojowa 0.1"
                    color: "#647b91"; font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Rectangle {
            id: drawer
            anchors.fill: parent
            visible: root.drawerOpen
            color: "#0d1622"
            z: 20
            Column {
                anchors.fill: parent; anchors.margins: 28; spacing: 18
                Row {
                    width: parent.width; height: 52
                    Text {
                        text: "Aplikacje"; color: "#f3f6fa"; font.pixelSize: 27
                        font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { width: 1; height: 1 }
                    Rectangle {
                        width: 48; height: 48; radius: 16; color: "#26394d"
                        anchors.right: parent.right
                        Text { anchors.centerIn: parent; text: "✕"; color: "#ffffff"; font.pixelSize: 20 }
                        MouseArea { anchors.fill: parent; onClicked: root.drawerOpen = false }
                    }
                }

                Rectangle {
                    width: parent.width; height: 54; radius: 17
                    color: "#1a2a3b"; border.width: 1; border.color: "#35516b"
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 17
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌕"; color: "#9bb1c5"; font.pixelSize: 24
                    }
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 48
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Szukaj aplikacji"; color: "#71879d"
                        visible: searchInput.text.length === 0; font.pixelSize: 15
                    }
                    TextInput {
                        id: searchInput
                        anchors.left: parent.left; anchors.leftMargin: 48
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#f3f6fa"; font.pixelSize: 15
                        onTextChanged: root.searchText = text
                    }
                }

                GridView {
                    id: appGrid
                    width: parent.width; height: parent.height - 142
                    clip: true; cellWidth: width / 3; cellHeight: 126
                    model: DesktopEntries.applications.values.filter(function(entry) {
                        if (!root.isVisibleApp(entry))
                            return false
                        const q = root.searchText.toLowerCase()
                        return q.length === 0 ||
                            (entry.name || "").toLowerCase().indexOf(q) !== -1 ||
                            (entry.genericName || "").toLowerCase().indexOf(q) !== -1
                    })
                    delegate: Item {
                        required property var modelData
                        width: appGrid.cellWidth; height: appGrid.cellHeight
                        Column {
                            anchors.fill: parent; anchors.margins: 7; spacing: 8
                            Rectangle {
                                width: 62; height: 62; radius: 21
                                color: "#21394d"; anchors.horizontalCenter: parent.horizontalCenter
                                Image {
                                    anchors.centerIn: parent
                                    width: 38
                                    height: 38
                                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                            Text {
                                width: parent.width; text: modelData.name || "Aplikacja"
                                color: "#eaf0f5"; font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: modelData.execute() }
                    }
                }
            }
        }

        Rectangle {
            id: controlCenter
            anchors.fill: parent
            visible: root.controlOpen
            color: "#0d1622"
            z: 21
            Column {
                anchors.fill: parent; anchors.margins: 30; spacing: 20
                Row {
                    width: parent.width; height: 54
                    Text {
                        text: "Centrum telefonu"; color: "#f3f6fa"; font.pixelSize: 25
                        font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: 48; height: 48; radius: 16; color: "#26394d"
                        anchors.right: parent.right
                        Text { anchors.centerIn: parent; text: "✕"; color: "#ffffff"; font.pixelSize: 20 }
                        MouseArea { anchors.fill: parent; onClicked: root.controlOpen = false }
                    }
                }
                Rectangle {
                    width: parent.width; height: 92; radius: 22; color: "#1c3045"
                    Column {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 20; spacing: 5
                        Text {
                            text: "ZAMARTEOS PURE"; color: "#ffffff"
                            font.pixelSize: 21; font.weight: Font.DemiBold; font.letterSpacing: 1
                        }
                        Text {
                            text: "Ustawienia telefonu • Fairphone 4"
                            color: "#b7c8d6"; font.pixelSize: 13
                        }
                    }
                }
                Text {
                    text: "USTAWIENIA SYSTEMOWE"; color: "#8ea4ba"
                    font.pixelSize: 12; font.weight: Font.DemiBold; font.letterSpacing: 1.5
                }
                Repeater {
                    model: [
                        { title: "Sieć i połączenia", subtitle: "Wi-Fi, Bluetooth, sieć komórkowa", words: ["network", "connections", "wifi", "sieć"] },
                        { title: "Dźwięk i wibracje", subtitle: "Głośność, dzwonek, urządzenia audio", words: ["sound", "audio", "volume", "dźwięk"] },
                        { title: "Wyświetlacz i tapety", subtitle: "Jasność, ekran, wygląd systemu", words: ["display", "appearance", "wallpaper", "wyświetlacz"] },
                        { title: "Bateria i zasilanie", subtitle: "Stan baterii i oszczędzanie energii", words: ["power", "battery", "bateria"] },
                        { title: "Aplikacje", subtitle: "Zainstalowane programy i uprawnienia", words: ["applications", "software", "apps", "aplikacje"] },
                        { title: "Prywatność i bezpieczeństwo", subtitle: "Blokada ekranu i ochrona danych", words: ["privacy", "security", "lock", "bezpieczeństwo"] },
                        { title: "Język i region", subtitle: "Polski język i formaty regionalne", words: ["language", "locale", "region", "język"] },
                        { title: "Informacje o systemie", subtitle: "Wersja ZamarteOS i urządzenie", words: ["about", "system information", "informacje"] }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 66; radius: 18
                        color: "#192b3d"; border.width: 1; border.color: "#2e465d"
                        Column {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 16; spacing: 3
                            Text {
                                text: modelData.title; color: "#edf3f8"
                                font.pixelSize: 15; font.weight: Font.DemiBold
                            }
                            Text {
                                text: modelData.subtitle; color: "#91a4ba"; font.pixelSize: 11
                                elide: Text.ElideRight; width: controlCenter.width - 92
                            }
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"; color: "#a9d7c9"; font.pixelSize: 25
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.launchByKeywords(modelData.words, modelData.title)
                        }
                    }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: "Menu jest przygotowane. Poszczególne ustawienia będą stopniowo podłączane do usług systemowych — nie pokazujemy fikcyjnych przełączników."
                    color: "#8095a9"; font.pixelSize: 11
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 22
            visible: root.notice.length > 0; z: 30
            width: Math.min(parent.width - 48, noticeText.implicitWidth + 34)
            height: 52; radius: 17; color: "#30465a"
            Text {
                id: noticeText; anchors.centerIn: parent
                text: root.notice; color: "#ffffff"; font.pixelSize: 13
            }
        }
    }

    // A narrow always-visible launcher bar keeps the app drawer reachable
    // while ordinary application windows are in the foreground.
    PanelWindow {
        anchors { top: true; left: true; right: true }
        implicitHeight: 56
        aboveWindows: true
        exclusiveZone: 0
        focusable: false
        color: "#101b29"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: "ZAMARTEOS"
            color: "#eaf2f5"
            font.pixelSize: 14
            font.weight: Font.Bold
            font.letterSpacing: 1.4
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(root.now, "HH:mm")
                color: "#d7e3ed"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: 42; height: 40; radius: 13
                color: "#294157"
                Text { anchors.centerIn: parent; text: "▦"; color: "#e8f1f6"; font.pixelSize: 19 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.controlOpen = false
                        root.drawerOpen = !root.drawerOpen
                    }
                }
            }

            Rectangle {
                width: 42; height: 40; radius: 13
                color: "#294157"
                Text { anchors.centerIn: parent; text: "☷"; color: "#e8f1f6"; font.pixelSize: 19 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.drawerOpen = false
                        root.controlOpen = !root.controlOpen
                    }
                }
            }
        }
    }
}
