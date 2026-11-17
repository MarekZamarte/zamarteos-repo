# ZamarteOS

**ZamarteOS Pure dla Fairphone 4** — samodzielny system Linux ARM64 z własną
powłoką Wayland i aplikacjami ZamarteOS.

Sailfish OS nie jest docelowym interfejsem ani wymaganym systemem bazowym.
Zachowujemy techniczne komponenty potrzebne do obsługi FP4: kernel, firmware,
sterowniki, modem, IMS/Q6Voice, routing dźwięku rozmów, sieć, baterię i dotyk.
Nie dostarczamy Android userspace ani usług Google.

## Stan projektu

- Powłoka ZamarteOS Pure jest integrowana z przypiętą bazą sprzętową FP4.
- Host aplikacji podłącza natywne moduły Telefon, Wiadomości, Kontakty, Pliki,
  Kalkulator, Kalendarz, Zegar, Edytor, Pogoda, Poczta, Notatki i Monitor.
- Centrum ustawień ma prawdziwe sterowanie Wi-Fi, Bluetooth, jasnością i głośnością multimediów; stan radia
  komórkowego jest tylko odczytywany, aby nie wyłączyć modemu.
- Aparat uruchamia Megapixels, a przeglądarka uruchamia Epiphany.
- Kompilacja i statyczne testy CI nie potwierdzają jeszcze działania
  na fizycznym telefonie. Wymagane są testy rozmów, dźwięku, SMS, aparatu,
  sieci, baterii, dotyku i uśpienia na Fairphone 4.

## Dokumentacja

- [Plan architektury i etapów](docs/BUILD-PLAN.md)
- [Stan sprzętu FP4 i kryteria dźwięku połączeń](docs/FP4-STATUS.md)
- [Opis powłoki ZamarteOS po polsku](packaging/zamarteos-shell/README-PL.md)
- [PR ZamarteOS Pure FP4](https://github.com/MarekZamarte/zamarteos-repo/pull/1)

Żaden workflow nie flashuje telefonu. Obraz testowy nie jest wydaniem do
instalacji, dopóki CI i testy sprzętowe nie przejdą.
