# Powłoka ZamarteOS Pure — etap 0.2.3

## Cel

ZamarteOS Pure ma zastąpić cały system widoczny dla użytkownika na
Fairphone 4. Nie jest aplikacją Sailfish Silica, motywem ani samym launcherem.
Docelowo użytkownik ma widzieć własny ekran blokady, pulpit, pasek stanu,
powiadomienia, centrum sterowania, ustawienia, menu i aplikacje ZamarteOS.

Sailfish OS nie jest wymaganym elementem docelowego systemu. Bazą jest
natywny userspace Arch Linux ARM z własną sesją Wayland ZamarteOS.

## Co działa w kodzie powłoki na tym etapie

- własna sesja Hyprland/Wayland uruchamiana z tty1;
- ekran główny, szuflada aplikacji i wyszukiwanie wpisów .desktop;
- hostowanie natywnych modułów Phone, Messages i Files z przypiętej bazy FP4;
- osobne pozycje Telefon, Wiadomości, Kontakty i Pliki w menu aplikacji;\n- edytowalna baza kontaktów wspólna z Telefonem i Wiadomościami (dodawanie, usuwanie i wybieranie numeru);
- moduły Telefonu i Wiadomości są ładowane przy starcie sesji i wywołują
  warmUp(), aby nasłuch ModemManager nie zależał od otwartego okna;
- Centrum telefonu odczytuje i zmienia Wi-Fi, dane komórkowe, Bluetooth,
  jasność ekranu i głośność multimediów przez nmcli, bluetoothctl,
  brightnessctl i pamixer; wyświetla też odczyt baterii i wersję jądra;
- blokada sesji z uwierzytelnianiem PAM;
- polski locale i polski układ klawiatury.

Połączenia i SMS korzystają z ModemManager. Moduł Telefonu korzysta z
callaudiod/Q6Voice oraz istniejącego routingu FP4; ta zmiana nie modyfikuje
modemu ani ścieżki audio rozmów.

## Zaplecze techniczne, które pozostaje

Powłoka nie zastępuje i nie usuwa kernela, firmware, sterowników,
modemu, usług IMS/VoLTE, Q6Voice/q6voiced, NetworkManager, PipeWire,
WirePlumber, D-Bus, systemd ani obsługi sprzętu FP4. Te komponenty są
niezbędne do działania telefonu. Interfejs użytkownika jest budowany
osobno i ma być w całości ZamarteOS.

## Co nie jest jeszcze ukończone

Ta powłoka nie oznacza, że wszystkie aplikacje są gotowe. Aparat, galeria,
kalendarz, pełne ustawienia systemowe, aktualizacje i kopie zapasowe
wymagają dalszej integracji. Nieaktywne funkcje mają pozostać ukryte.
Każda nowa kontrolka ma wywoływać prawdziwą usługę, a nie zmieniać tylko
wygląd przełącznika.

## Testowanie

CI sprawdza budowanie pakietu ARM64, qmllint i integrację z przypiętą bazą.
To nie jest jeszcze test uruchomienia na fizycznym Fairphone 4. Na telefonie
trzeba sprawdzić uruchomienie modułów, nasłuch połączeń w tle, identyfikację
dzwoniącego, dźwięk rozmowy, SMS, sieć, Bluetooth, jasność, głośność,
klawiaturę polską, blokadę, aparat, baterię i uśpienie.

Obraz nie jest gotowy do flashowania tylko dlatego, że CI zbudowało pakiet
lub przeszły kontrole statyczne. Flashowanie wymaga osobnej decyzji.
