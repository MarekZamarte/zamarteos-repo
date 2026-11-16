import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    id: app
    initialPage: Component {
        Page {
            id: page
            allowedOrientations: Orientation.Portrait
            property bool loading: false
            property string currentSummary: "Wpisz miejscowość, aby pobrać pogodę."
            property var forecastRows: []

            function description(code) {
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

            function dayName(dateText, index) {
                if (index === 0) return "Dzisiaj"
                if (index === 1) return "Jutro"
                var p = dateText.split("-")
                var d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]))
                return Qt.locale("pl_PL").standaloneDayName((d.getDay() + 6) % 7 + 1, Locale.LongFormat)
            }

            function loadWeather() {
                var place = city.text.trim()
                if (place.length < 2) {
                    currentSummary = "Wpisz nazwę miejscowości."
                    return
                }
                loading = true
                currentSummary = "Wyszukiwanie miejscowości…"
                forecastRows = []
                var geo = new XMLHttpRequest()
                geo.onreadystatechange = function() {
                    if (geo.readyState !== XMLHttpRequest.DONE) return
                    if (geo.status !== 200) {
                        currentSummary = "Błąd wyszukiwania. Sprawdź połączenie z internetem."
                        loading = false
                        return
                    }
                    var results = null
                    try { results = JSON.parse(geo.responseText).results } catch (e) {}
                    if (!results || results.length === 0) {
                        currentSummary = "Nie znaleziono miejscowości."
                        loading = false
                        return
                    }
                    getForecast(results[0])
                }
                geo.open("GET", "https://geocoding-api.open-meteo.com/v1/search?name="
                         + encodeURIComponent(place) + "&count=1&language=pl&format=json")
                geo.send()
            }

            function getForecast(location) {
                var req = new XMLHttpRequest()
                req.onreadystatechange = function() {
                    if (req.readyState !== XMLHttpRequest.DONE) return
                    loading = false
                    if (req.status !== 200) {
                        currentSummary = "Nie udało się pobrać prognozy."
                        return
                    }
                    var data = null
                    try { data = JSON.parse(req.responseText) } catch (e) {}
                    if (!data || !data.current || !data.daily) {
                        currentSummary = "Serwis zwrócił nieprawidłowe dane."
                        return
                    }
                    currentSummary = location.name + ", " + location.country
                            + "\nTeraz: " + Math.round(data.current.temperature_2m) + " °C, "
                            + description(data.current.weather_code)
                            + "\nOdczuwalna: " + Math.round(data.current.apparent_temperature)
                            + " °C • Wiatr: " + Math.round(data.current.wind_speed_10m) + " km/h"
                    var rows = []
                    for (var i = 0; i < 7; i++) {
                        rows.push({
                            day: dayName(data.daily.time[i], i),
                            date: data.daily.time[i].substring(8,10) + "."
                                  + data.daily.time[i].substring(5,7),
                            desc: description(data.daily.weather_code[i]),
                            min: Math.round(data.daily.temperature_2m_min[i]),
                            max: Math.round(data.daily.temperature_2m_max[i])
                        })
                    }
                    forecastRows = rows
                }
                var url = "https://api.open-meteo.com/v1/forecast?latitude="
                        + location.latitude + "&longitude=" + location.longitude
                        + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m"
                        + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
                        + "&forecast_days=7&timezone=auto"
                req.open("GET", url)
                req.send()
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: column.height + Theme.paddingLarge
                clip: true

                Column {
                    id: column
                    width: parent.width
                    spacing: Theme.paddingMedium

                    PageHeader {
                        title: "Pogoda"
                        description: "Prognoza na 7 dni"
                    }

                    TextField {
                        id: city
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        placeholderText: "Np. Bydgoszcz"
                        label: "Miejscowość"
                        EnterKey.onClicked: page.loadWeather()
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.loading ? "Pobieranie…" : "Pokaż pogodę"
                        enabled: !page.loading
                        onClicked: page.loadWeather()
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: page.currentSummary
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    SectionHeader { text: "Najbliższe 7 dni" }

                    Repeater {
                        model: page.forecastRows
                        delegate: BackgroundItem {
                            width: parent.width
                            height: 76
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Theme.horizontalPageMargin
                                width: parent.width - 2 * Theme.horizontalPageMargin
                                spacing: 3
                                Row {
                                    width: parent.width
                                    Label {
                                        width: parent.width * 0.34
                                        text: modelData.day + " " + modelData.date
                                        color: Theme.primaryColor
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                    Label {
                                        width: parent.width * 0.42
                                        text: modelData.desc
                                        color: Theme.secondaryColor
                                        font.pixelSize: Theme.fontSizeSmall
                                        truncationMode: TruncationMode.Fade
                                    }
                                    Label {
                                        width: parent.width * 0.24
                                        text: modelData.min + "° / " + modelData.max + "°"
                                        color: Theme.highlightColor
                                        font.pixelSize: Theme.fontSizeSmall
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: "Źródło danych: Open-Meteo. Wymagane połączenie z internetem."
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeTiny
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
