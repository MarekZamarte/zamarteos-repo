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
            property string weatherText: "Wpisz miejscowość i pobierz prognozę."
            property string forecastText: ""
            property bool weatherLoading: false

            function weatherDescription(code) {
                if (code === 0) return "Bezchmurnie"
                if (code === 1) return "Przeważnie słonecznie"
                if (code === 2) return "Częściowe zachmurzenie"
                if (code === 3) return "Pochmurno"
                if (code === 45 || code === 48) return "Mgła"
                if (code >= 51 && code <= 57) return "Mżawka"
                if (code >= 61 && code <= 67) return "Deszcz"
                if (code >= 71 && code <= 77) return "Śnieg"
                if (code >= 80 && code <= 82) return "Przelotne opady"
                if (code === 85 || code === 86) return "Przelotny śnieg"
                if (code >= 95) return "Burza"
                return "Warunki zmienne"
            }

            function loadWeather() {
                var place = cityField.text.trim()
                if (place.length < 2) {
                    weatherText = "Wpisz nazwę miejscowości."
                    forecastText = ""
                    return
                }

                weatherLoading = true
                weatherText = "Szukam miejscowości…"
                forecastText = ""

                var geo = new XMLHttpRequest()
                geo.onreadystatechange = function() {
                    if (geo.readyState !== XMLHttpRequest.DONE)
                        return
                    if (geo.status !== 200) {
                        weatherText = "Nie udało się pobrać lokalizacji. Sprawdź internet."
                        weatherLoading = false
                        return
                    }

                    var locations
                    try {
                        locations = JSON.parse(geo.responseText).results
                    } catch (e) {
                        locations = null
                    }
                    if (!locations || locations.length === 0) {
                        weatherText = "Nie znaleziono miejscowości."
                        weatherLoading = false
                        return
                    }

                    var loc = locations[0]
                    fetchForecast(loc.latitude, loc.longitude, loc.name, loc.country)
                }
                geo.open("GET", "https://geocoding-api.open-meteo.com/v1/search?name="
                         + encodeURIComponent(place) + "&count=1&language=pl&format=json")
                geo.send()
            }

            function fetchForecast(latitude, longitude, place, country) {
                var request = new XMLHttpRequest()
                request.onreadystatechange = function() {
                    if (request.readyState !== XMLHttpRequest.DONE)
                        return
                    weatherLoading = false
                    if (request.status !== 200) {
                        weatherText = "Nie udało się pobrać prognozy."
                        forecastText = ""
                        return
                    }

                    var data
                    try {
                        data = JSON.parse(request.responseText)
                    } catch (e) {
                        weatherText = "Otrzymano nieprawidłowe dane pogody."
                        forecastText = ""
                        return
                    }

                    var current = data.current
                    var daily = data.daily
                    weatherText = place + ", " + country + "\\n"
                            + Math.round(current.temperature_2m) + " °C • "
                            + weatherDescription(current.weather_code) + "\\n"
                            + "Odczuwalna: " + Math.round(current.apparent_temperature)
                            + " °C • Wiatr: " + Math.round(current.wind_speed_10m) + " km/h"
                    if (daily && daily.time && daily.time.length > 0) {
                        var lines = []
                        for (var i = 0; i < daily.time.length; i++) {
                            var date = daily.time[i].split("-")
                            lines.push(date[2] + "." + date[1] + ": "
                                       + weatherDescription(daily.weather_code[i]) + ", "
                                       + Math.round(daily.temperature_2m_min[i]) + "° / "
                                       + Math.round(daily.temperature_2m_max[i]) + "°")
                        }
                        forecastText = lines.join("\\n")
                    }
                }

                var url = "https://api.open-meteo.com/v1/forecast?latitude="
                        + latitude + "&longitude=" + longitude
                        + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m"
                        + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
                        + "&forecast_days=3&timezone=auto"
                request.open("GET", url)
                request.send()
            }

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

                    SectionHeader { text: "Pogoda" }

                    TextField {
                        id: cityField
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        x: Theme.horizontalPageMargin
                        placeholderText: "Wpisz miejscowość"
                        label: "Miejscowość"
                        EnterKey.onClicked: home.loadWeather()
                    }

                    Button {
                        text: home.weatherLoading ? "Pobieranie…" : "Pobierz pogodę"
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: !home.weatherLoading
                        onClicked: home.loadWeather()
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: home.weatherText
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: home.forecastText
                        color: Theme.primaryColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: "Dane pogodowe: Open-Meteo. Do wyszukania wysyłana jest tylko nazwa miejscowości."
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeTiny
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
