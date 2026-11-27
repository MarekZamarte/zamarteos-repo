# Zamarte Pogoda — Sailfish OS

Aplikacja pogodowa dla Zamartego (53.59500, 17.98528), napisana w Qt/QML i Sailfish Silica. Pobiera aktualną pogodę oraz prognozę 7-dniową z Open-Meteo, bez klucza API.

## Budowanie

Projekt wymaga Sailfish SDK i targetu aarch64. Workflow GitHub Actions w `.github/workflows/build-zamarte-pogoda.yml` przygotowuje środowisko i publikuje RPM jako artefakt. Po zakończeniu sprawdź wynik uruchomienia w Actions.
