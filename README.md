# ZamarteOS Pure — Fairphone 4

Natywny system Linux dla Fairphone 4 (SM7225), bez Androida jako systemu użytkownika, bez Halium, Ubuntu Touch i Lomiri.

## Założenia
- Arch Linux ARM / aarch64 jako baza użytkowa.
- Linux dla SM6350/SM7225 z obsługą Fairphone 4.
- Hyprland jako kompozytor; docelowo własna powłoka ZamarteOS w Quickshell/QML.
- ModemManager, Q6Voice i q6voiced dla dźwięku rozmów.
- Własny ekran główny, centrum sterowania i aplikacje ZamarteOS.
- Firmware Qualcomm pozostaje ukrytą warstwą sprzętową, jeśli jest niezbędny.

Androidowy format `boot.img` jest wyłącznie formatem startowym wymaganym przez bootloader FP4. Nie oznacza instalacji Androida.

## Stan
- [x] Wybrana baza sprzętowa FP4 z udokumentowanym testem dźwięku rozmów.
- [x] Utworzona osobna gałąź rozwojowa.
- [x] Powtarzalny build referencyjnej bazy FP4 w GitHub Actions (obraz referencyjny nr 43; nie jest wydaniem).
- [x] Pierwszy prototyp powłoki QML: ekran główny, szuflada aplikacji i centrum telefonu.
- [x] Kompilacja pakietu powłoki QML/PAM w ARM64 CI; dodano kontrolę `qmllint` do kolejnego przebiegu CI.
- [x] Przygotowany skrypt integrujący własną powłokę i blokadę z sesją obrazu FP4.
- [ ] Doprowadzenie powłoki do poziomu codziennego użycia: pełna klawiatura ekranowa, gesty, blokada, powiadomienia i działające centrum ustawień.
- [ ] Test uruchomienia, blokady i odblokowania na fizycznym FP4.
- [ ] Potwierdzenie działania Telefonu, SMS, Kontaktów, Plików i przeglądarki oraz testy fizycznego telefonu.
- [ ] Obraz do wgrania dopiero po testach.

**Bezpieczeństwo:** żaden skrypt w tym repozytorium nie flashuje telefonu. Obraz nr 43 jest bazą referencyjną opartą na sprzętowej bazie Moarchy z powłoką ZamarteOS; nie jest wydaniem i nie wolno go instalować przed testami na fizycznym FP4.

Szczegóły: [plan budowy](docs/BUILD-PLAN.md) i [status FP4](docs/FP4-STATUS.md).


## Ostatnia kontrola

- Powłoka ma szybkie kafelki Telefonu, Wiadomości, Kontaktów, Plików i Internetu. Do pakietu powłoki dodano zależność od przeglądarki Epiphany dla ARM64, a wyszukiwarka sprawdza także identyfikator wpisu aplikacji.
- Kolejny przebieg ARM64 CI uruchomi `qmllint` na rzeczywistym pliku `shell.qml`; do czasu zielonego wyniku kontrola nie jest uznana za zaliczoną. Zależność Epiphany i kafelek przeglądarki także wymagają potwierdzenia w nowym buildzie.
- Obecność wpisów .desktop i pakietów nie jest dowodem działania aplikacji. Testy dotyku, gestów, połączeń, Caller ID, ringback i audio wymagają fizycznego FP4.
