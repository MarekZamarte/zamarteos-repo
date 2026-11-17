# ZamarteOS Pure FP4 — build plan

## Docelowa decyzja architektoniczna

ZamarteOS Pure ma być samodzielnym systemem dla Fairphone 4, a nie motywem,
launcherem ani aplikacją uruchamianą wewnątrz Sailfish OS. Sailfish OS nie
jest docelowym systemem użytkownika i nie może być wymagany do uruchomienia
ZamarteOS Pure.

Punktem wyjścia jest natywny userspace Linux ARM64 oparty na przypiętej bazie
sprzętowej FP4: Arch Linux ARM + systemd, kernel Linux SM6350/SM7225, device
tree i firmware FP4, Hyprland, własna powłoka ZamarteOS w Quickshell/QML,
natywne aplikacje Linux/Wayland i własne aplikacje ZamarteOS.

Nie dostarczamy Android userspace, Android UI ani usług Google. Kontener
Android boot image jest wyłącznie formatem startowym wymaganym przez
bootloader, a nie systemem Android.

## Co ma zastąpić ZamarteOS

W obrazie końcowym użytkownik ma widzieć wyłącznie ZamarteOS. Do zastąpienia
lub integracji z własnymi odpowiednikami są wszystkie warstwy użytkowe:
ekran blokady, ekran główny, nawigacja, pasek stanu, powiadomienia, szybkie
ustawienia, centrum sterowania, menu i wyszukiwanie aplikacji, ustawienia,
Telefon, kontakty, historia połączeń, interfejs połączenia przychodzącego,
Wiadomości/SMS, pliki, galeria, aparat, przeglądarka, kalendarz i pozostałe
podstawowe aplikacje, klawiatura ekranowa, polski układ, podpowiedzi,
aktualizacje, kopie zapasowe i pierwsze uruchomienie.

Nie wolno uznawać pustego kafelka, skrótu do nieistniejącej aplikacji ani
przemianowanego ekranu Moarchy za ukończoną funkcję. Każda pozycja menu ma
uruchamiać rzeczywistą aplikację albo pozostać ukryta do czasu jej wdrożenia.

## Co zachowujemy jako techniczne zaplecze

Nie usuwamy działających komponentów tylko dlatego, że pochodzą z bazy
sprzętowej. Zachowujemy i integrujemy kernel, device tree, firmware i sterowniki
Qualcomm/FP4; modem, SIM, ModemManager, usługi IMS/VoLTE i q6voiced/Q6Voice;
routing dźwięku rozmów, mikrofon, słuchawkę i głośnik; Wi-Fi, Bluetooth, NFC,
GPS i dane komórkowe; ekran, dotyk, czujniki, aparat, lampę błyskową; baterię,
ładowanie, klawisze fizyczne, uśpienie i wybudzanie; PipeWire/WirePlumber,
NetworkManager, systemd, D-Bus, PAM i usługi wymagane przez sprzęt lub
aplikacje.

Zachowanie zaplecza nie oznacza zachowania interfejsu Moarchy/Omarchy ani
Sailfish. Usługi i sterowniki mogą pozostać, ale ich branding, menu i
powłoka nie mogą być widoczne jako interfejs telefonu. Nie zmieniamy
konfiguracji modemu ani działającego routingu audio bez konkretnej potrzeby
i testu regresji.

## Obecna implementacja i ograniczenia

Powłoka ZamarteOS jest uruchamiana jako własna sesja Wayland z tty1. Hostuje
natywne moduły przypiętej bazy FP4: Phone, Messages, Contacts, Files,
Calculator, Calendar, Clock, Editor, Weather, Mail, Keep i Vitals. Osobne
wpisy aplikacji ZamarteOS uruchamiają te moduły przez IPC powłoki. Telefon i
Wiadomości są ładowane od początku sesji, aby nasłuch ModemManager działał
również przy zamkniętych oknach.

Centrum ustawień odczytuje i zmienia Wi-Fi i Bluetooth, jasność ekranu
oraz głośność multimediów przez nmcli, bluetoothctl, brightnessctl
i pamixer. Stan radia komórkowego jest tylko odczytywany — powłoka nie
wyłącza modemu, aby nie przerwać połączeń. Panel wyświetla również stan
baterii i wersję jądra.
Aparat uruchamia natywny Megapixels, a Internet — Epiphany. Kontakty używają
wspólnej lokalnej bazy z Telefonem i Wiadomościami.

To jest działający kod integracyjny i nadal etap rozwojowy, a nie gotowe
wydanie systemu. Galeria, pełna warstwa ustawień, powiadomienia, aktualizacje
i kopie zapasowe wymagają dalszej pracy. Testy statyczne nie potwierdzają
działania na fizycznym telefonie.

Osobny prototyp Sailfish Silica został zamknięty i nie jest celem ZamarteOS
Pure. Nie rozwijamy aplikacji Sailfish zamiast pełnego systemu Pure.

## Milestone 1 — powtarzalna baza sprzętowa

Zbudować przypiętą bazę FP4 w CI jako obraz referencyjny, bez flashowania.
Zachować logi, manifest pakietów, sumy kontrolne i pochodzenie źródeł.
Warunki: kernel i pakiety ARM64 budują się z przypiętych źródeł; pakiet
ZamarteOS shell przechodzi qmllint; obraz DEVICE=fp4 buduje się i przechodzi
weryfikator; obraz zawiera powłokę ZamarteOS, kernel FP4, modem i wymagane
komponenty Q6Voice/IMS; weryfikator odrzuca obraz, w którym tty1 uruchamia
natywną powłokę Moarchy zamiast sesji ZamarteOS.

## Milestone 2 — kompletna powłoka ZamarteOS

Dokończyć pasek stanu, powiadomienia, pełne centrum sterowania i wszystkie
ustawienia. Każdy widoczny przycisk musi wykonywać rzeczywistą akcję.
Wdrożyć polską klawiaturę i sprawdzić polskie znaki oraz podpowiedzi na
ekranie telefonu. Utrzymać priorytet ekranu połączenia przychodzącego nad
pulpitem i menu aplikacji.

## Milestone 3 — aplikacje i integracja sprzętu

Rozszerzyć zestaw aplikacji o galerię i brakujące podstawowe narzędzia.
Zweryfikować połączenia przychodzące i wychodzące, identyfikację numeru,
dźwięk w obie strony, dzwonek/ringback, SMS, dane komórkowe, Wi-Fi,
Bluetooth, GPS, aparat, czujniki, uśpienie, ładowanie i aktualizacje.

## Milestone 3 — podstawowe aplikacje i integracja sprzętu

Dostarczyć prawdziwe aplikacje Telefon, Kontakty, SMS, Pliki, Galeria,
Aparat, Przeglądarka i Ustawienia. Zweryfikować połączenia przychodzące i
wychodzące, identyfikację numeru, dźwięk w obie strony, dzwonek, SMS, dane
komórkowe, Wi-Fi, Bluetooth, GPS, aparat, czujniki, uśpienie, ładowanie i
aktualizacje.

## Milestone 4 — kandydat do wydania

Wydanie flashowalne powstaje dopiero po powtarzalnych testach na fizycznym
FP4. Wymagane są testy rozmów przez słuchawkę i głośnik, mikrofonu,
dzwonka/ringback, SIM/IMS, dotyku, klawiatury, aparatu, baterii i wznowienia
po uśpieniu. Obecnego systemu telefonu nie ruszamy, dopóki użytkownik
wyraźnie nie zdecyduje o testowym flashowaniu.
