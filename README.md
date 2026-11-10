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
- [ ] Powtarzalny build referencyjnej bazy FP4 w GitHub Actions.
- [x] Pierwszy prototyp powłoki QML: ekran główny, szuflada aplikacji i centrum telefonu.
- [ ] Kompilacja pakietu QML/PAM w ARM64 CI.
- [x] Przygotowany skrypt integrujący własną powłokę i blokadę z sesją obrazu FP4.
- [ ] Doprowadzenie powłoki do poziomu codziennego użycia: klawiatura ekranowa, gesty, blokada i powiadomienia.
- [ ] Test uruchomienia, blokady i odblokowania na fizycznym FP4.
- [ ] Integracja aplikacji i testy fizycznego telefonu.
- [ ] Obraz do wgrania dopiero po testach.

**Bezpieczeństwo:** żaden skrypt w tym repozytorium nie flashuje telefonu. Pierwszy build CI jest bazą referencyjną, nie wydaniem ZamarteOS i nie wolno go instalować.

Szczegóły: [plan budowy](docs/BUILD-PLAN.md) i [status FP4](docs/FP4-STATUS.md).
