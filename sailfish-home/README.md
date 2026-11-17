# ZamarteOS Home — panel narzędziowy Sailfish

Natywna aplikacja Qt Quick / Sailfish Silica dla Fairphone 4 z Sailfish OS 5.0.

## Funkcje zaimplementowane w kodzie

- zegar i data;
- rozpoczęcie połączenia przez systemowy handler `tel:<numer>`;
- rozpoczęcie tworzenia SMS przez systemowy handler `sms:<numer>`;
- otwieranie adresu WWW lub wyszukiwanie w DuckDuckGo w domyślnej przeglądarce;
- pobieranie aktualnej pogody i prognozy 3-dniowej z Open-Meteo;
- komunikaty błędów sieci oraz limit 15 sekund dla żądań pogodowych.

Aplikacja deklaruje uprawnienie Sailjail `Internet`, wymagane przez zapytania pogodowe. Nie wymaga usług Google.

## Ważne ograniczenia

- To panel narzędziowy uruchamiany jako zwykła aplikacja Sailfish. Nie zastępuje Lipstick ani systemowego ekranu głównego.
- Telefon i SMS są przekazywane do systemowych handlerów URL. To system Sailfish wykonuje właściwe połączenie lub otwiera kompozytor wiadomości.
- Kontakty, aparat i ustawienia nie są pokazywane jako działające skróty, ponieważ nie zostały jeszcze podłączone do sprawdzonych API urządzenia.
- Samo zbudowanie RPM nie potwierdza działania na telefonie. Wymagane są testy połączenia, SMS, przeglądarki i dostępu do internetu na fizycznym FP4.

## Budowanie

Projekt używa qmake i biblioteki SailfishApp. Należy budować w Sailfish SDK na celu ARM64 zgodnym z Sailfish OS 5.0.
