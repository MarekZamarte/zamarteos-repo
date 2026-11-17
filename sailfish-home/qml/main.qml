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
            property string weatherText: "Wpisz miejscowość, aby pobrać aktualną pogodę."
            property string forecastText: ""
            property bool weatherLoading: false
            property int weatherRequestId: 0
            property var activeWeatherRequest: null

            function setStatus(message) {
                statusText = message
            }

            function normalizedNumber(value) {
                return value.replace(/[^0-9+*#]/g, "")
            }

            function startCall() {
                var number = normalizedNumber(phoneField.text)
                if (number.length < 3) {
                    setStatus("Wpisz prawidłowy numer telefonu.")
                    return
                }
                var opened = Qt.openUrlExternally("tel:" + number)
                setStatus(opened
                          ? "Przekazano numer do systemowej aplikacji Telefon."
                          : "System nie przyjął polecenia połączenia.")
            }

            function startSms() {
                var number = normalizedNumber(smsField.text)
                if (number.length < 3) {
                    setStatus("Wpisz numer odbiorcy SMS.")
                    return
                }
                var opened = Qt.openUrlExternally("sms:" + number)
                setStatus(opened
                          ? "Przekazano numer do systemowej aplikacji Wiadomości."
                          : "System nie przyjął polecenia SMS.")
            }

            function openWebSearch() {
                var query = webField.text.trim()
                if (query.length === 0) {
                    setStatus("Wpisz adres strony lub szukaną frazę.")
                    return
                }

                var url = query.indexOf("://") >= 0
                        ? query
                        : (query.indexOf(".") >= 0 && query.indexOf(" ") < 0
                           ? "https://" + query
                           : "https://duckduckgo.com/?q=" + encodeURIComponent(query))
                var opened = Qt.openUrlExternally(url)
                setStatus(opened
                          ? "Przekazano stronę do domyślnej przeglądarki."
                          : "Nie udało się otworzyć przeglądarki.")
            }

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

            function failWeather(message) {
                weatherLoading = false
                activeWeatherRequest = null
                weatherTimeout.stop()
                weatherText = message
                forecastText = ""
            }

            function loadWeather() {
                var place = cityField.text.trim()
                if (place.length < 2) {
                    weatherText = "Wpisz nazwę miejscowości."
                    forecastText = ""
                    return
                }

                weatherRequestId += 1
                var requestId = weatherRequestId
                weatherLoading = true
                weatherText = "Łączenie z usługą pogodową…"
                forecastText = ""

                var geo = new XMLHttpRequest()
                activeWeatherRequest = geo
                weatherTimeout.restart()

                geo.onreadystatechange = function() {
                    if (requestId !== home.weatherRequestId
                            || geo.readyState !== XMLHttpRequest.DONE)
                        return

                    if (geo.status !== 200) {
                        home.failWeather("Nie można pobrać lokalizacji. Sprawdź połączenie z internetem.")
                        return
                    }

                    var locations = null
                    try {
                        locations = JSON.parse(geo.responseText).results
                    } catch (error) {
                        home.failWeather("Usługa lokalizacji zwróciła nieprawidłowe dane.")
                        return
                    }

                    if (!locations || locations.length === 0) {
                        home.failWeather("Nie znaleziono takiej miejscowości.")
                        return
                    }

                    var location = locations[0]
                    home.fetchForecast(requestId, location.latitude,
                                       location.longitude, location.name,
                                       location.country)
                }

                geo.open("GET", "https://geocoding-api.open-meteo.com/v1/search?name="
                         + encodeURIComponent(place) + "&count=1&language=pl&format=json")
                geo.send()
            }

            function fetchForecast(requestId, latitude, longitude, place, country) {
                if (requestId !== weatherRequestId)
                    return

                var request = new XMLHttpRequest()
                activeWeatherRequest = request
                weatherTimeout.restart()

                request.onreadystatechange = function() {
                    if (requestId !== home.weatherRequestId
                            || request.readyState !== XMLHttpRequest.DONE)
                        return

                    weatherTimeout.stop()
                    home.activeWeatherRequest = null
                    home.weatherLoading = false

                    if (request.status !== 200) {
                        home.weatherText = "Nie udało się pobrać prognozy. Sprawdź internet."
                        home.forecastText = ""
                        return
                    }

                    var data = null
                    try {
                        data = JSON.parse(request.responseText)
                    } catch (error) {
                        home.weatherText = "Otrzymano nieprawidłowe dane pogody."
                        home.forecastText = ""
                        return
                    }

                    if (!data.current || !data.daily) {
                        home.weatherText = "Usługa pogodowa nie zwróciła aktualnych danych."
                        home.forecastText = ""
                        return
                    }

                    var current = data.current
                    home.weatherText = place + ", " + country + "\n"
                            + Math.round(current.temperature_2m) + " °C • "
                            + home.weatherDescription(current.weather_code) + "\n"
                            + "Odczuwalna: "
                            + Math.round(current.apparent_temperature) + " °C • Wiatr: "
                            + Math.round(current.wind_speed_10m) + " km/h"

                    var daily = data.daily
                    var lines = []
                    if (daily.time && daily.time.length > 0) {
                        for (var i = 0; i < daily.time.length; i++) {
                            var date = daily.time[i].split("-")
                            lines.push(date[2] + "." + date[1] + ": "
                                       + home.weatherDescription(daily.weather_code[i]) + ", "
                                       + Math.round(daily.temperature_2m_min[i]) + "° / "
                                       + Math.round(daily.temperature_2m_max[i]) + "°")
                        }
                    }
                    home.forecastText = lines.join("\n")
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

            Timer {
                id: weatherTimeout
                interval: 15000
                repeat: false
                onTriggered: {
                    if (home.activeWeatherRequest) {
                        home.activeWeatherRequest.abort()
                        home.failWeather("Przekroczono czas oczekiwania na internet (15 s).")
                    }
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
                        description: "Panel narzędziowy • Fairphone 4"
                    }

                    Rectangle {
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        height: 142
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

                    SectionHeader { text: "Telefon" }

                    TextField {
                        id: phoneField
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        x: Theme.horizontalPageMargin
                        label: "Numer telefonu"
                        placeholderText: "+48 000 000 000"
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        EnterKey.onClicked: home.startCall()
                    }

                    Button {
                        text: "Zadzwoń"
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: home.startCall()
                    }

                    SectionHeader { text: "Wiadomości SMS" }

                    TextField {
                        id: smsField
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        x: Theme.horizontalPageMargin
                        label: "Numer odbiorcy"
                        placeholderText: "+48 000 000 000"
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        EnterKey.onClicked: home.startSms()
                    }

                    Button {
                        text: "Napisz SMS"
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: home.startSms()
                    }

                    SectionHeader { text: "Internet" }

                    TextField {
                        id: webField
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        x: Theme.horizontalPageMargin
                        label: "Adres strony lub wyszukiwanie"
                        placeholderText: "np. duckduckgo.com"
                        EnterKey.onClicked: home.openWebSearch()
                    }

                    Button {
                        text: "Otwórz w przeglądarce"
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: home.openWebSearch()
                    }

                    SectionHeader { text: "Pogoda" }

                    TextField {
                        id: cityField
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        x: Theme.horizontalPageMargin
                        label: "Miejscowość"
                        placeholderText: "Wpisz nazwę miejscowości"
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
                        text: "Pogoda: Open-Meteo. Wysyłana jest tylko nazwa wpisanej miejscowości."
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeTiny
                    }

                    SectionHeader { text: "Status" }

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
                        text: "To niezależna aplikacja. Nie zastępuje ekranu systemowego Sailfish OS ani nie zmienia modemu, sterowników i dźwięku rozmów."
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }
        }
    }
}
