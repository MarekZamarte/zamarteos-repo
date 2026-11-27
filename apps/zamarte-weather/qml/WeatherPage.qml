import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property string apiUrl: "https://api.open-meteo.com/v1/forecast?latitude=53.59500&longitude=17.98528&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m&hourly=temperature_2m,precipitation_probability,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=7&timezone=Europe%2FWarsaw"
    property string temperature: "—°"
    property string feels: "—°"
    property string humidity: "—%"
    property string wind: "— km/h"
    property string condition: "Pobieranie prognozy…"
    property string errorText: ""
    property string updatedText: ""
    property var days: []
    property var hours: []
    property bool loading: false

    function description(code) {
        if (code === 0) return "Bezchmurnie"
        if (code === 1) return "Przeważnie pogodnie"
        if (code === 2) return "Częściowe zachmurzenie"
        if (code === 3) return "Pochmurno"
        if (code === 45 || code === 48) return "Mgła"
        if (code >= 51 && code <= 57) return "Mżawka"
        if (code >= 61 && code <= 67) return "Deszcz"
        if (code >= 71 && code <= 77) return "Śnieg"
        if (code >= 80 && code <= 82) return "Przelotny deszcz"
        if (code >= 85 && code <= 86) return "Przelotny śnieg"
        if (code >= 95) return "Burza"
        return "Zmienna pogoda"
    }

    function symbol(code) {
        if (code === 0) return "☀"
        if (code <= 2) return "☀"
        if (code === 3) return "☁"
        if (code === 45 || code === 48) return "≋"
        if (code >= 51 && code <= 67) return "☂"
        if (code >= 71 && code <= 86) return "❄"
        if (code >= 95) return "⚡"
        return "☁"
    }

    function dayLabel(date, index) {
        if (index === 0) return "Dzisiaj"
        if (index === 1) return "Jutro"
        var d = new Date(date + "T12:00:00")
        var names = ["Niedziela", "Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota"]
        return names[d.getDay()]
    }

    function refreshWeather() {
        loading = true
        errorText = ""
        var req = new XMLHttpRequest()
        req.open("GET", apiUrl)
        req.onreadystatechange = function() {
            if (req.readyState !== XMLHttpRequest.DONE) return
            loading = false
            if (req.status < 200 || req.status >= 300) {
                errorText = "Nie udało się pobrać prognozy. Sprawdź połączenie z internetem."
                return
            }
            try {
                var data = JSON.parse(req.responseText)
                temperature = Math.round(data.current.temperature_2m) + "°"
                feels = Math.round(data.current.apparent_temperature) + "°"
                humidity = Math.round(data.current.relative_humidity_2m) + "%"
                wind = Math.round(data.current.wind_speed_10m) + " km/h"
                condition = description(data.current.weather_code)
                updatedText = "Aktualizacja: " + new Date().toLocaleTimeString(Qt.locale("pl_PL"), "HH:mm")
                var result = []
                for (var i = 0; i < data.daily.time.length; i++) {
                    result.push({
                        label: dayLabel(data.daily.time[i], i),
                        icon: symbol(data.daily.weather_code[i]),
                        weather: description(data.daily.weather_code[i]),
                        max: Math.round(data.daily.temperature_2m_max[i]),
                        min: Math.round(data.daily.temperature_2m_min[i]),
                        rain: data.daily.precipitation_probability_max[i]
                    })
                }
                days = result
                var hourResult = []
                var now = new Date()
                for (var h = 0; h < data.hourly.time.length && hourResult.length < 8; h++) {
                    var hourDate = new Date(data.hourly.time[h])
                    if (hourDate.getTime() >= now.getTime() - 3600000) {
                        hourResult.push({
                            time: hourDate.toLocaleTimeString(Qt.locale("pl_PL"), "HH:mm"),
                            icon: symbol(data.hourly.weather_code[h]),
                            temp: Math.round(data.hourly.temperature_2m[h]) + "°",
                            rain: data.hourly.precipitation_probability[h]
                        })
                    }
                }
                hours = hourResult
            } catch (e) {
                errorText = "Nie można odczytać danych prognozy."
            }
        }
        req.send()
    }

    PullDownMenu {
        MenuItem {
            text: "Odśwież prognozę"
            onClicked: page.refreshWeather()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge
        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Zamarte Pogoda"
                description: "Zamarte · Polska"
            }

            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: hero.height + Theme.paddingLarge * 2
                radius: Theme.paddingLarge
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.22)

                Column {
                    id: hero
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Theme.paddingLarge
                    width: parent.width - Theme.paddingLarge * 2
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        text: page.symbol ? "" : ""
                        visible: false
                    }
                    Label {
                        width: parent.width
                        text: page.condition
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.primaryColor
                    }
                    Label {
                        width: parent.width
                        text: page.temperature
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeHuge * 1.65
                        color: Theme.highlightColor
                    }
                    Label {
                        width: parent.width
                        text: "Odczuwalna " + page.feels
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                    }
                    Label {
                        width: parent.width
                        text: page.updatedText
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                    }
                }
            }

            Row {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Repeater {
                    model: [
                        { title: "Wilgotność", value: page.humidity, icon: "◌" },
                        { title: "Wiatr", value: page.wind, icon: "↗" }
                    ]
                    delegate: Rectangle {
                        width: (parent.width - Theme.paddingSmall) / 2
                        height: Theme.itemSizeLarge
                        radius: Theme.paddingMedium
                        color: Theme.rgba(Theme.secondaryHighlightColor, 0.12)
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Label {
                                width: parent.parent.width
                                text: modelData.title
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                            }
                            Label {
                                width: parent.parent.width
                                text: modelData.value
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primaryColor
                            }
                        }
                    }
                }
            }

            SectionHeader { text: "Najbliższe godziny" }

            SilicaListView {
                width: parent.width
                height: Math.min(Theme.itemSizeLarge * 1.55, Theme.itemSizeLarge * 1.55)
                model: page.hours
                orientation: ListView.Horizontal
                clip: true
                delegate: BackgroundItem {
                    width: Theme.itemSizeLarge * 1.25
                    height: parent.height
                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.paddingSmall
                        Label {
                            width: parent.width
                            text: modelData.time
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                        Label {
                            width: parent.width
                            text: modelData.icon
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.highlightColor
                        }
                        Label {
                            width: parent.width
                            text: modelData.temp
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        Label {
                            width: parent.width
                            text: modelData.rain + "%"
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                }
            }

            SectionHeader { text: "Prognoza na 7 dni" }

            Repeater {
                model: page.days
                delegate: BackgroundItem {
                    width: content.width
                    height: Theme.itemSizeLarge
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        spacing: Theme.paddingSmall

                        Label {
                            width: parent.width * 0.25
                            text: modelData.label
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        Label {
                            width: parent.width * 0.12
                            text: modelData.icon
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.highlightColor
                        }
                        Label {
                            width: parent.width * 0.26
                            text: modelData.max + "° / " + modelData.min + "°"
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        Label {
                            width: parent.width * 0.28
                            text: modelData.rain === null ? "—" : "Opady " + modelData.rain + "%"
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                }
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                text: page.errorText
                visible: page.errorText.length > 0
                color: Theme.errorColor
                wrapMode: Text.Wrap
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.loading ? "Pobieranie…" : "Odśwież pogodę"
                enabled: !page.loading
                onClicked: page.refreshWeather()
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                text: "Dane pogodowe: Open-Meteo"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
        }
    }

    Component.onCompleted: refreshWeather()
}
