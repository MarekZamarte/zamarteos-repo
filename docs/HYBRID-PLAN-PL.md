# ZamarteOS Hybrid — Fairphone 4

## Cel

Osobny wariant ZamarteOS dla Fairphone 4 (FP4, SM7225), w którym własny interfejs i aplikacje ZamarteOS działają w linuksowym userspace, a niezbędna zgodność ze sprzętem jest zapewniana przez istniejący stos Halium 11 / Android 11.

To NIE jest wariant Pure. Nie wolno przenosić zmian z tej gałęzi do Pure bez osobnej decyzji.

## Zweryfikowana baza sprzętowa

- Urządzenie: Fairphone 4, kod urządzenia `FP4`.
- Istniejący port: UBports Reference Device Port `fairphone-fp4`.
- Repozytorium: https://gitlab.com/ubports/porting/reference-device-ports/android11/fairphone-4/fairphone-fp4
- Gałąź referencyjna: `focal` (do sprawdzenia w audycie źródeł).
- Warstwa zgodności: Halium 11 / Android 11.
- Źródło statusu: https://devices.ubuntu-touch.io/device/fp4/

Karta urządzenia UBports opisuje działające podstawowe funkcje telefonu, rozmowy, dźwięk słuchawki, głośnik i mikrofon. VoLTE jest opisane jako eksperymentalne i zależne od operatora. To dowód istnienia dojrzałej bazy sprzętowej, ale NIE dowód, że ZamarteOS Hybrid już działa.

## Docelowa architektura

1. **Boot / kernel** — urządzeniowy kernel i konfiguracja startowa zgodne z portem FP4 Halium 11.
2. **Warstwa sprzętowa** — tylko niezbędne usługi i biblioteki zgodności Android/Halium (Binder, libhybris/libgbinder oraz usługi urządzenia), uruchamiane w odizolowanym środowisku.
3. **System użytkownika** — docelowo linuksowy userspace ZamarteOS. Nie kopiujemy Ubuntu Touch UI ani aplikacji Android.
4. **Interfejs** — własna sesja ZamarteOS; polski język, własny ekran główny i ustawienia.
5. **Telefonia/audio** — osobny etap integracji i testów: modem, RIL/Radio, routing audio, Q6Voice, mikrofon, słuchawka, głośnik, ringback. Nie zmieniać konfiguracji modemu bez logów i testu porównawczego.

## Etapy — bez skrótów

- [x] Utworzyć niezależną gałąź rozwojową Hybrid.
- [x] Wskazać istniejący port FP4 Halium 11 jako źródło do audytu.
- [ ] Sklonować i zarchiwizować źródła portu oraz deviceinfo w GitHub Actions.
- [ ] Audytować manifest, kernel, vendor blobs, firmware, partycje i wymagania wersji bazowego firmware.
- [ ] Zbudować artefakty warstwy sprzętowej dla FP4 z przypiętych źródeł.
- [ ] Przygotować rootfs ZamarteOS i integrację usług Halium.
- [ ] Zintegrować własną sesję ZamarteOS.
- [ ] Dodać testy offline rootfs, manifestu pakietów i sum kontrolnych.
- [ ] Przetestować start na fizycznym FP4.
- [ ] Przetestować rozmowy przychodzące/wychodzące, mikrofon, słuchawkę, głośnik i ringback.
- [ ] Dopiero po pozytywnych testach przygotować instrukcję instalacji.

## Ważne ograniczenia

Pierwszy workflow w tej gałęzi jest audytem źródeł, a nie pełnym buildem obrazu. Nie wolno nazywać artefaktu audytu gotowym systemem. Pełny build wymaga potwierdzenia manifestu Halium, zależności urządzenia, źródeł kernela i vendor blobs. Nie wolno zgadywać repozytoriów ani rewizji.

Żaden workflow tej gałęzi nie może uruchamiać fastboot, ADB flash ani modyfikować telefonu. Obraz testowy będzie publikowany dopiero po pełnym buildzie i audycie.
