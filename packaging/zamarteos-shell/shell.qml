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
    property bool homeOpen: true
    property string searchText: ""
    property string notice: ""
    property string lockInput: ""
    property string lockError: ""
    property bool firstbootCopied: false

    FileView {
        id: firstbootPinFile
        path: "/home/moarchy/PIERWSZE-URUCHOMIENIE.txt"
        printErrors: false
    }

    FileView {
        id: firstbootNoticeState
        path: "/home/moarchy/.zamarteos-firstboot-notice-dismissed"
        printErrors: false
    }

    property string firstbootPin: {
        const match = firstbootPinFile.text().match(/Twój prywatny PIN: ([0-9]{8})/)
        return match ? match[1] : ""
    }
    property bool firstbootNoticeDismissed: firstbootNoticeState.text().trim() === "1"

    property string activePlugin: ""

    QtObject {
        id: pluginShellApi
        function isPluginOpen(pluginId) {
            return root.activePlugin === pluginId
        }
        function hide(pluginId) {
            root.hidePlugin(pluginId)
        }
        function summon(pluginId, payload) {
            root.summonPlugin(pluginId, payload || "{}")
        }
        function toggle(pluginId, payload) {
            root.togglePlugin(pluginId, payload || "{}")
        }
    }

    Loader {
        id: phonePlugin
        active: true
        source: "file:///usr/share/moarchy/plugins/moarchy.phone/Phone.qml"
        onLoaded: {
            item.shell = pluginShellApi
            item.manifest = ({ id: "moarchy.phone", name: "Telefon" })
            item.warmUp()
        }
    }
    Loader {
        id: messagesPlugin
        active: true
        source: "file:///usr/share/moarchy/plugins/moarchy.messages/Messages.qml"
        onLoaded: {
            item.shell = pluginShellApi
            item.manifest = ({ id: "moarchy.messages", name: "Wiadomości" })
            item.warmUp()
        }
    }
    Loader {
        id: filesPlugin
        active: true
        source: "file:///usr/share/moarchy/plugins/moarchy.files/Files.qml"
        onLoaded: {
            item.shell = pluginShellApi
            item.manifest = ({ id: "moarchy.files", name: "Pliki" })
        }
    }

    Connections {
        target: phonePlugin.item
        function onOpenedChanged() {
            if (phonePlugin.item && !phonePlugin.item.opened &&
                    root.activePlugin === "moarchy.phone") {
                root.activePlugin = ""
                root.homeOpen = true
            }
        }
    }
    Connections {
        target: messagesPlugin.item
        function onOpenedChanged() {
            if (messagesPlugin.item && !messagesPlugin.item.opened &&
                    root.activePlugin === "moarchy.messages") {
                root.activePlugin = ""
                root.homeOpen = true
            }
        }
    }
    Connections {
        target: filesPlugin.item
        function onOpenedChanged() {
            if (filesPlugin.item && !filesPlugin.item.opened &&
                    root.activePlugin === "moarchy.files") {
                root.activePlugin = ""
                root.homeOpen = true
            }
        }
    }

    function pluginItem(pluginId) {
        if (pluginId === "moarchy.phone") return phonePlugin.item
        if (pluginId === "moarchy.messages") return messagesPlugin.item
        if (pluginId === "moarchy.files") return filesPlugin.item
        return null
    }

    function hidePlugin(pluginId) {
        const item = pluginItem(pluginId)
        if (!item) return
        if (typeof item.close === "function") item.close()
        if (pluginId === "moarchy.files" && item.appWindow)
            item.appWindow.hide()
        // An incoming call is not dismissible by the home button. Keep its
        // window in front rather than hiding the call screen under the home UI.
        if (pluginId === "moarchy.phone" && item.incoming && item.opened) {
            activePlugin = pluginId
            homeOpen = false
            return
        }
        if (activePlugin === pluginId) {
            activePlugin = ""
            homeOpen = true
        }
    }

    function summonPlugin(pluginId, payload) {
        const item = pluginItem(pluginId)
        if (!item || typeof item.open !== "function") {
            showNotice("Ta funkcja nie jest dostępna w tym obrazie.")
            return false
        }
        if (activePlugin && activePlugin !== pluginId) {
            const previousId = activePlugin
            const previous = pluginItem(previousId)
            if (previousId === "moarchy.phone" && previous &&
                    previous.incoming && previous.opened) {
                showNotice("Najpierw zakończ obsługę połączenia przychodzącego.")
                return false
            }
            if (previous && typeof previous.close === "function") previous.close()
            if (previous && previous.appWindow) previous.appWindow.hide()
        }
        activePlugin = pluginId
        homeOpen = false
        drawerOpen = false
        controlOpen = false
        item.open(payload || "{}")
        return true
    }

    function togglePlugin(pluginId, payload) {
        if (activePlugin === pluginId) hidePlugin(pluginId)
        else summonPlugin(pluginId, payload)
    }

    property string wifiState: "nieodczytany"
    property string wwanState: "nieodczytany"
    property string bluetoothState: "nieodczytany"
    property int brightnessPercent: -1
    property int volumePercent: -1
    property bool volumeMuted: false
    property string batteryInfo: "Odczytuję stan baterii…"
    property string kernelInfo: "Odczytuję wersję jądra…"

    function refreshSettings() {
        wifiQuery.running = true
        wwanQuery.running = true
        bluetoothQuery.running = true
        brightnessQuery.running = true
        volumeQuery.running = true
        muteQuery.running = true
        batteryQuery.running = true
        kernelQuery.running = true
    }

    function setWifi(enabled) {
        wifiAction.exec(["nmcli", "radio", "wifi", enabled ? "on" : "off"])
    }
    function setMobileData(enabled) {
        wwanAction.exec(["nmcli", "radio", "wwan", enabled ? "on" : "off"])
    }
    function setBluetooth(enabled) {
        bluetoothAction.exec(["bluetoothctl", "power", enabled ? "on" : "off"])
    }
    function changeBrightness(delta) {
        if (brightnessPercent < 0) { showNotice("Nie można odczytać jasności ekranu."); return }
        const next = Math.max(1, Math.min(100, brightnessPercent + delta))
        brightnessAction.exec(["brightnessctl", "set", String(next) + "%"])
    }
    function changeVolume(delta) {
        if (volumePercent < 0) { showNotice("Nie można odczytać głośności."); return }
        const next = Math.max(0, Math.min(100, volumePercent + delta))
        volumeAction.exec(["pamixer", "--set-volume", String(next)])
    }
    function toggleMute() {
        muteAction.exec(["pamixer", "--toggle-mute"])
    }

    Process {
        id: wifiQuery
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector { onStreamFinished: root.wifiState = this.text.trim() }
    }
    Process {
        id: wwanQuery
        command: ["nmcli", "-t", "-f", "WWAN", "radio"]
        stdout: StdioCollector { onStreamFinished: root.wwanState = this.text.trim() }
    }
    Process {
        id: bluetoothQuery
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text
                if (output.indexOf("No default controller available") !== -1)
                    root.bluetoothState = "brak adaptera"
                else if (output.indexOf("Powered: yes") !== -1)
                    root.bluetoothState = "włączony"
                else if (output.indexOf("Powered: no") !== -1)
                    root.bluetoothState = "wyłączony"
                else
                    root.bluetoothState = "niedostępny"
            }
        }
    }
    Process {
        id: brightnessQuery
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split(",")
                root.brightnessPercent = fields.length >= 5
                    ? parseInt(fields[4].replace("%", "")) : -1
            }
        }
    }
    Process {
        id: volumeQuery
        command: ["pamixer", "--get-volume"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(this.text.trim())
                root.volumePercent = isNaN(value) ? -1 : value
            }
        }
    }
    Process {
        id: muteQuery
        command: ["pamixer", "--get-mute"]
        stdout: StdioCollector { onStreamFinished: root.volumeMuted = this.text.trim() === "true" }
    }
    Process {
        id: batteryQuery
        command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] || continue; c=$(cat \"$b/capacity\"); s=$(cat \"$b/status\" 2>/dev/null); printf '%s%% • %s\\n' \"$c\" \"$s\"; exit 0; done; printf 'Brak danych baterii\\n'"]
        stdout: StdioCollector { onStreamFinished: root.batteryInfo = this.text.trim() }
    }
    Process {
        id: kernelQuery
        command: ["uname", "-r"]
        stdout: StdioCollector { onStreamFinished: root.kernelInfo = this.text.trim() }
    }
    Process {
        id: wifiAction
        onExited: (exitCode, exitStatus) => {
            root.showNotice(exitCode === 0 ? "Zmieniono stan Wi-Fi." : "Nie udało się zmienić Wi-Fi.")
            root.refreshSettings()
        }
    }
    Process {
        id: wwanAction
        onExited: (exitCode, exitStatus) => {
            root.showNotice(exitCode === 0 ? "Zmieniono stan danych komórkowych." : "Nie udało się zmienić danych komórkowych.")
            root.refreshSettings()
        }
    }
    Process {
        id: bluetoothAction
        onExited: (exitCode, exitStatus) => {
            root.showNotice(exitCode === 0 ? "Wysłano polecenie do Bluetooth." : "Nie udało się zmienić Bluetooth.")
            root.refreshSettings()
        }
    }
    Process {
        id: brightnessAction
        onExited: (exitCode, exitStatus) => {
            root.showNotice(exitCode === 0 ? "Zmieniono jasność ekranu." : "Nie udało się zmienić jasności.")
            root.refreshSettings()
        }
    }
    Process {
        id: volumeAction
        onExited: (exitCode, exitStatus) => {
            root.showNotice(exitCode === 0 ? "Zmieniono głośność multimediów." : "Nie udało się zmienić głośności.")
            root.refreshSettings()
        }
    }
    Process {
        id: muteAction
        onExited: (exitCode, exitStatus) => {
            root.showNotice(exitCode === 0 ? "Zmieniono wyciszenie multimediów." : "Nie udało się zmienić wyciszenia.")
            root.refreshSettings()
        }
    }

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
        // Desktop-file IDs are internal compatibility identifiers, not UI labels.
        // Hide branded display text only; otherwise Phone, Messages and Files
        // disappear even though their visible names are neutral.
        const name = String(entry.name || "").toLowerCase()
        const genericName = String(entry.genericName || "").toLowerCase()
        return name.indexOf("moarchy") === -1 && name.indexOf("omarchy") === -1 &&
               genericName.indexOf("moarchy") === -1 && genericName.indexOf("omarchy") === -1
    }

    function launchEntry(entry, label) {
        if (!entry || typeof entry.execute !== "function") {
            showNotice(label + ": wpis aplikacji nie ma polecenia uruchomienia.")
            return false
        }
        try {
            entry.execute()
            drawerOpen = false
            controlOpen = false
            homeOpen = false
            return true
        } catch (error) {
            console.warn("ZamarteOS: nie udało się uruchomić", label, error)
            showNotice(label + ": nie udało się uruchomić aplikacji.")
            return false
        }
    }

    function launchByKeywords(keywords, label) {
        const joined = keywords.join(" ").toLowerCase()
        if (joined.indexOf("phone") !== -1 || joined.indexOf("telefon") !== -1)
            return summonPlugin("moarchy.phone", "{}")
        if (joined.indexOf("messages") !== -1 || joined.indexOf("sms") !== -1)
            return summonPlugin("moarchy.messages", "{}")
        if (joined.indexOf("contacts") !== -1 || joined.indexOf("kontakty") !== -1)
            return summonPlugin("moarchy.phone", "{\\"contacts\\":true}")
        if (joined.indexOf("files") !== -1 || joined.indexOf("pliki") !== -1)
            return summonPlugin("moarchy.files", "{}")
        const entries = DesktopEntries.applications.values
        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            if (!isVisibleApp(entry))
                continue
            const haystack = ((entry.name || "") + " " + (entry.genericName || "") + " " + (entry.id || "")).toLowerCase()
            for (let j = 0; j < keywords.length; ++j) {
                if (haystack.indexOf(keywords[j]) !== -1)
                    return launchEntry(entry, label)
            }
        }
        console.warn("ZamarteOS: brak dopasowania dla", label,
                     "Dostępne wpisy:", entries.map(function(entry) {
                         return String(entry.name || "") + " [" + String(entry.id || "") + "]"
                     }).join("; "))
        showNotice(label + ": brak pasującego wpisu aplikacji.")
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

    IpcHandler {
        target: "zamarteos-apps"
        function open(app: string): void {
            if (app === "phone")
                root.summonPlugin("moarchy.phone", "{}")
            else if (app === "messages")
                root.summonPlugin("moarchy.messages", "{}")
            else if (app === "contacts")
                root.summonPlugin("moarchy.phone", "{\\"contacts\\":true}")
            else if (app === "files")
                root.summonPlugin("moarchy.files", "{}")
            else
                root.showNotice("Nieznana aplikacja ZamarteOS.")
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
            root.lockError = success ? "" : "PIN nieprawidłowy"
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
                        text: "Wprowadź PIN"
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
                                        } else if (root.lockInput.length < 12) {
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
        // The home surface must be shown at login. Hide it only while a
        // launched application is in the foreground.
        visible: root.homeOpen || root.drawerOpen || root.controlOpen
        aboveWindows: root.drawerOpen || root.controlOpen || root.homeOpen
        exclusiveZone: 0
        focusable: root.drawerOpen || root.controlOpen || root.homeOpen
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
            interactive: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

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
                            { title: "Kontakty", subtitle: "Osoby i numery", symbol: "♙", words: ["contacts", "address book", "kontakty"] },
                            { title: "Internet", subtitle: "Przeglądarka WWW", symbol: "◎", words: ["epiphany", "web browser", "browser", "przeglądarka"] },
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
                        MouseArea { anchors.fill: parent; onClicked: { root.controlOpen = true; root.refreshSettings() } }
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
                        id: drawerTitle
                        width: parent.width - 60
                        height: parent.height
                        text: "Aplikacje"; color: "#f3f6fa"; font.pixelSize: 27
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }
                    Rectangle {
                        width: 48; height: 48; radius: 16; color: "#26394d"
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
                    clip: true; interactive: true
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: width / 3; cellHeight: 126
                    model: DesktopEntries.applications.values.filter(function(entry) {
                        if (!root.isVisibleApp(entry))
                            return false
                        const q = root.searchText.toLowerCase()
                        return q.length === 0 ||
                            (entry.name || "").toLowerCase().indexOf(q) !== -1 ||
                            (entry.genericName || "").toLowerCase().indexOf(q) !== -1 ||
                            (entry.id || "").toLowerCase().indexOf(q) !== -1
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
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.launchEntry(modelData, modelData.name || "Aplikacja")
                        }
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
            Flickable {
                anchors.fill: parent
                anchors.margins: 30
                clip: true
                contentWidth: width
                contentHeight: controlColumn.implicitHeight
                interactive: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: controlColumn
                    width: parent.width
                    spacing: 20
                Row {
                    width: parent.width; height: 54
                    Text {
                        id: controlTitle
                        width: parent.width - 60
                        height: parent.height
                        text: "Centrum telefonu"; color: "#f3f6fa"; font.pixelSize: 25
                        font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }
                    Rectangle {
                        width: 48; height: 48; radius: 16; color: "#26394d"
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
                    text: "ŁĄCZNOŚĆ"
                    color: "#8ea4ba"; font.pixelSize: 12
                    font.weight: Font.DemiBold; font.letterSpacing: 1.5
                }
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 12
                    Repeater {
                        model: [
                            { title: "Wi-Fi", state: root.wifiState, action: "wifi" },
                            { title: "Dane komórkowe", state: root.wwanState, action: "wwan" },
                            { title: "Bluetooth", state: root.bluetoothState, action: "bluetooth" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: (controlColumn.width - 12) / 2
                            height: 88; radius: 18
                            color: "#192b3d"; border.width: 1; border.color: "#2e465d"
                            Column {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 14; spacing: 5
                                Text { text: modelData.title; color: "#edf3f8"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                Text { text: modelData.state; color: "#a9d7c9"; font.pixelSize: 12 }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.action === "wifi")
                                        root.setWifi(root.wifiState !== "enabled")
                                    else if (modelData.action === "wwan")
                                        root.setMobileData(root.wwanState !== "enabled")
                                    else
                                        root.setBluetooth(root.bluetoothState !== "włączony")
                                }
                            }
                        }
                    }
                }
                Text {
                    text: "EKRAN I DŹWIĘK"
                    color: "#8ea4ba"; font.pixelSize: 12
                    font.weight: Font.DemiBold; font.letterSpacing: 1.5
                }
                Rectangle {
                    width: parent.width; height: 88; radius: 18
                    color: "#192b3d"; border.width: 1; border.color: "#2e465d"
                    Row {
                        anchors.fill: parent; anchors.margins: 14; spacing: 10
                        Column {
                            width: parent.width - 116
                            anchors.verticalCenter: parent.verticalCenter; spacing: 5
                            Text { text: "Jasność ekranu"; color: "#edf3f8"; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Text { text: root.brightnessPercent >= 0 ? root.brightnessPercent + "%" : "brak odczytu"; color: "#a9d7c9"; font.pixelSize: 12 }
                        }
                        Rectangle {
                            width: 48; height: 48; radius: 15; color: "#294157"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "−"; color: "#ffffff"; font.pixelSize: 25 }
                            MouseArea { anchors.fill: parent; onClicked: root.changeBrightness(-10) }
                        }
                        Rectangle {
                            width: 48; height: 48; radius: 15; color: "#294157"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 25 }
                            MouseArea { anchors.fill: parent; onClicked: root.changeBrightness(10) }
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 88; radius: 18
                    color: "#192b3d"; border.width: 1; border.color: "#2e465d"
                    Row {
                        anchors.fill: parent; anchors.margins: 14; spacing: 10
                        Column {
                            width: parent.width - 174
                            anchors.verticalCenter: parent.verticalCenter; spacing: 5
                            Text { text: "Głośność multimediów"; color: "#edf3f8"; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Text { text: root.volumePercent >= 0 ? root.volumePercent + "%" + (root.volumeMuted ? " • wyciszone" : "") : "brak odczytu"; color: "#a9d7c9"; font.pixelSize: 12 }
                        }
                        Rectangle {
                            width: 42; height: 48; radius: 15; color: "#294157"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "−"; color: "#ffffff"; font.pixelSize: 25 }
                            MouseArea { anchors.fill: parent; onClicked: root.changeVolume(-5) }
                        }
                        Rectangle {
                            width: 42; height: 48; radius: 15; color: root.volumeMuted ? "#8b5b55" : "#294157"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: root.volumeMuted ? "×" : "♪"; color: "#ffffff"; font.pixelSize: 21 }
                            MouseArea { anchors.fill: parent; onClicked: root.toggleMute() }
                        }
                        Rectangle {
                            width: 42; height: 48; radius: 15; color: "#294157"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 25 }
                            MouseArea { anchors.fill: parent; onClicked: root.changeVolume(5) }
                        }
                    }
                }
                Text {
                    text: "URZĄDZENIE"
                    color: "#8ea4ba"; font.pixelSize: 12
                    font.weight: Font.DemiBold; font.letterSpacing: 1.5
                }
                Rectangle {
                    width: parent.width; height: 76; radius: 18
                    color: "#192b3d"; border.width: 1; border.color: "#2e465d"
                    Column {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 16; spacing: 5
                        Text { text: "Bateria"; color: "#edf3f8"; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Text { text: root.batteryInfo; color: "#a9d7c9"; font.pixelSize: 12 }
                    }
                }
                Rectangle {
                    width: parent.width; height: 76; radius: 18
                    color: "#192b3d"; border.width: 1; border.color: "#2e465d"
                    Column {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 16; spacing: 5
                        Text { text: "Jądro Linux"; color: "#edf3f8"; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Text { text: root.kernelInfo; color: "#a9d7c9"; font.pixelSize: 12 }
                    }
                }
                Rectangle {
                    width: parent.width; height: 56; radius: 18
                    color: "#26394d"
                    Text {
                        anchors.centerIn: parent
                        text: "Odśwież stan urządzenia"
                        color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.refreshSettings() }
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: "Menu jest przygotowane. Poszczególne ustawienia będą stopniowo podłączane do usług systemowych — nie pokazujemy fikcyjnych przełączników."
                    color: "#8095a9"; font.pixelSize: 11
                }
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

        MouseArea {
            anchors.fill: parent
            z: 0
            property real pressY: 0
            onPressed: pressY = mouse.y
            onReleased: {
                if (mouse.y - pressY > 18) {
                    root.drawerOpen = false
                    root.homeOpen = false
                    root.controlOpen = true
                }
            }
        }

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
                Text { anchors.centerIn: parent; text: "⌂"; color: "#e8f1f6"; font.pixelSize: 22 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.drawerOpen = false
                        root.controlOpen = false
                        root.homeOpen = true
                    }
                }
            }

            Rectangle {
                width: 42; height: 40; radius: 13
                color: "#294157"
                Text { anchors.centerIn: parent; text: "▦"; color: "#e8f1f6"; font.pixelSize: 19 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.homeOpen = false
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
                        root.homeOpen = false
                        root.drawerOpen = false
                        root.controlOpen = !root.controlOpen
                    }
                }
            }
        }
    }
    // The per-device PIN is generated by the root first-boot service and shown
    // here, after the graphical session starts (the phone has no hardware keyboard).
    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        visible: root.firstbootPin.length === 8 && !root.firstbootNoticeDismissed
        aboveWindows: true
        exclusiveZone: 0
        focusable: true
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#b8000000"
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 36, 360)
            height: 310
            radius: 26
            color: "#142235"
            border.width: 1
            border.color: "#3a526b"

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Text {
                    width: parent.width
                    text: "Pierwsze uruchomienie"
                    color: "#f3f6fa"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Twój prywatny PIN do odblokowania telefonu"
                    color: "#b7c8d6"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: root.firstbootPin
                    color: "#d7f0e6"
                    font.pixelSize: 34
                    font.weight: Font.Bold
                    font.letterSpacing: 4
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Zapisz PIN w bezpiecznym miejscu. Możesz go później zmienić poleceniem passwd w Terminalu. Po zmianie usuń plik PIERWSZE-URUCHOMIENIE.txt."
                    color: "#91a4ba"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 50
                        radius: 16
                        color: "#294157"
                        Text {
                            anchors.centerIn: parent
                            text: root.firstbootCopied ? "Skopiowano" : "Skopiuj PIN"
                            color: "#f3f6fa"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.clipboardText = root.firstbootPin
                                root.firstbootCopied = true
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 50
                        radius: 16
                        color: "#d7f0e6"
                        Text {
                            anchors.centerIn: parent
                            text: "Zapisano"
                            color: "#142b2b"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: firstbootNoticeState.setText("1")
                        }
                    }
                }
            }
        }
    }

}
