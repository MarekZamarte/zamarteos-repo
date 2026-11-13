# ZamarteOS Hybrid — Fairphone 4

## Cel

Osobny wariant ZamarteOS dla Fairphone 4 (FP4, SM7225), w którym własny interfejs i aplikacje ZamarteOS działają w linuksowym userspace, a niezbędna zgodność ze sprzętem jest zapewniana przez istniejący stos Halium 11 / Android 11.

To NIE jest wariant Pure. Nie wolno przenosić zmian z tej gałęzi do Pure bez osobnej decyzji.

## Punkt wyjścia do audytu

- Urządzenie: Fairphone 4, kod urządzenia `FP4`.
- Istniejący port: UBports Reference Device Port `fairphone-fp4`.
- Repozytorium: https://gitlab.com/ubports/porting/reference-device-ports/android11/fairphone-4/fairphone-fp4
- Gałąź referencyjna: `focal` (do sprawdzenia w audycie źródeł).
- Warstwa zgodności: Halium 11 / Android 11.
- Źródło statusu: https://devices.ubuntu-touch.io/device/fp4/

Repozytorium portu urządzenia i osobne repozytorium kernela są publiczne. Jednak bieżąca strona deweloperska UBports oznacza FP4 jako urządzenie, które nie ma kompletnego portu w tym kanale. Dlatego traktujemy te źródła jako materiał do audytu, a nie jako potwierdzony, gotowy stos telefoniczny. Nie zakładamy, że rozmowy, audio ani VoLTE zadziałają bez własnego builda i testów.

## Docelowa architektura

1. **Boot / kernel** — urządzeniowy kernel i konfiguracja startowa zgodne z portem FP4 Halium 11.
2. **Warstwa sprzętowa** — tylko niezbędne usługi i biblioteki zgodności Android/Halium (Binder, libhybris/libgbinder oraz usługi urządzenia), uruchamiane w odizolowanym środowisku.
3. **System użytkownika** — docelowo linuksowy userspace ZamarteOS. Nie kopiujemy Ubuntu Touch UI ani aplikacji Android.
4. **Interfejs** — własna sesja ZamarteOS; polski język, własny ekran główny i ustawienia.
5. **Telefonia/audio** — osobny etap integracji i testów: modem, RIL/Radio, routing audio, Q6Voice, mikrofon, słuchawka, głośnik, ringback. Nie zmieniać konfiguracji modemu bez logów i testu porównawczego.

## Etapy — bez skrótów

- [x] Utworzyć niezależną gałąź rozwojową Hybrid.
- [x] Wskazać istniejący port FP4 Halium 11 jako źródło do audytu.
- [x] Dodać workflow pobierający źródła portu urządzenia oraz kandydujące źródła kernela.
- [ ] Zakończyć audyt deviceinfo i ustalić dokładne rewizje zgodnego kernela.
- [ ] Audytować vendor blobs, firmware, partycje i wymagania wersji bazowego firmware.
- [ ] Zbudować artefakty warstwy sprzętowej dla FP4 z przypiętych źródeł.
- [ ] Przygotować rootfs ZamarteOS i integrację usług Halium.
- [ ] Zintegrować własną sesję ZamarteOS.
- [ ] Dodać testy offline rootfs, manifestu pakietów i sum kontrolnych.
- [ ] Przetestować start na fizycznym FP4.
- [ ] Przetestować rozmowy przychodzące/wychodzące, mikrofon, słuchawkę, głośnik i ringback.
- [ ] Dopiero po pozytywnych testach przygotować instrukcję instalacji.

## Ważne ograniczenia

Pierwszy workflow w tej gałęzi jest audytem źródeł, a nie pełnym buildem obrazu. Repozytorium kernela jest pobierane z gałęzi `halium-11.0`, która jest gałęzią projektu UBports dla Halium 11. Nadal traktujemy je jako kandydata do audytu; przed kompilacją trzeba potwierdzić zgodność z parametrami deviceinfo i zapisać dokładny SHA. Nie wolno nazywać artefaktu audytu gotowym systemem. Pełny build wymaga potwierdzenia manifestu Halium, zależności urządzenia, zgodnych źródeł kernela i vendor blobs. Nie wolno zgadywać repozytoriów ani rewizji.

Żaden workflow tej gałęzi nie może uruchamiać fastboot, ADB flash ani modyfikować telefonu. Obraz testowy będzie publikowany dopiero po pełnym buildzie i audycie.
