import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property string apiUrl: "https://api.open-meteo.com/v1/forecast?latitude=53.59500&longitude=17.98528&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=7&timezone=Europe%2FWarsaw"
    property string temperature: "—°"
    property string feels: "—°"
    property string humidity: "—%"
    property string condition: "Pobieranie prognozy…"
    property string errorText: ""
    property var days: []
    property bool loading: false

    function description(code) {
        if (code === 0) return "Bezchmurnie"
        if (code <= 2) return "Pogodnie"
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
                errorText = "Nie udało się pobrać pogody. Sprawdź internet."
                return
            }
            try {
                var data = JSON.parse(req.responseText)
                temperature = Math.round(data.current.temperature_2m) + "°"
                feels = Math.round(data.current.apparent_temperature) + "°"
                humidity = Math.round(data.current.relative_humidity_2m) + "%"
                condition = description(data.current.weather_code)
                var result = []
                for (var i = 0; i < data.daily.time.length; i++) {
                    result.push({
                        label: dayLabel(data.daily.time[i], i),
                        weather: description(data.daily.weather_code[i]),
                        max: Math.round(data.daily.temperature_2m_max[i]),
                        min: Math.round(data.daily.temperature_2m_min[i]),
                        rain: data.daily.precipitation_probability_max[i]
                    })
                }
                days = result
            } catch (e) {
                errorText = "Nie można odczytać danych prognozy."
            }
        }
        req.send()
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
                description: "Zamarte, powiat tucholski"
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
                font.pixelSize: Theme.fontSizeHuge * 1.5
                color: Theme.highlightColor
            }
            Label {
                width: parent.width
                text: "Odczuwalna " + page.feels + "   Wilgotność " + page.humidity
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
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
                            width: parent.width * 0.29
                            text: modelData.label
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width * 0.28
                            text: modelData.max + "° / " + modelData.min + "°"
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Label {
                            width: parent.width * 0.30
                            text: modelData.rain === null ? "" : "Opady " + modelData.rain + "%"
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Theme.fontSizeSmall
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
        }
    }
    Component.onCompleted: refreshWeather()
}
