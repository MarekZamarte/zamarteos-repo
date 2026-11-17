# Powłoka ZamarteOS Pure — etap 0.2

## Cel

ZamarteOS Pure ma zastąpić cały system widoczny dla użytkownika na
Fairphone 4. Nie jest aplikacją Sailfish Silica, motywem ani samym launcherem.
Docelowo użytkownik ma widzieć własny ekran blokady, pulpit, pasek stanu,
powiadomienia, centrum sterowania, ustawienia, menu i aplikacje ZamarteOS.

Sailfish OS nie jest wymaganym elementem docelowego systemu. Bazą jest
natywny userspace Arch Linux ARM z własną sesją Wayland ZamarteOS.

## Co zapewnia ta powłoka na obecnym etapie

- własna sesja Hyprland/Wayland uruchamiana z tty1;
- ekran główny i zegar;
- szuflada aplikacji z wyszukiwaniem;
- pasek ZamarteOS i wejście do centrum sterowania;
- blokada sesji z uwierzytelnianiem PAM;
- polski locale i polski układ klawiatury;
- uruchamianie zainstalowanych aplikacji Linux przez ich desktop entries.

## Zaplecze techniczne, które pozostaje

Powłoka nie zastępuje i nie usuwa kernela, firmware, sterowników,
modemu, usług IMS/VoLTE, Q6Voice/q6voiced, NetworkManager, PipeWire,
WirePlumber, D-Bus, systemd ani obsługi sprzętu FP4. Te komponenty są
niezbędne do działania telefonu. Interfejs użytkownika jest budowany
osobno i ma być w całości ZamarteOS.

## Co nie jest jeszcze ukończone

Sama powłoka i jej kafelki nie oznaczają, że wszystkie aplikacje są gotowe.
Telefon, Kontakty, SMS, aparat, galeria, ustawienia i inne programy muszą
być dostarczone jako prawdziwe aplikacje lub poprawnie zintegrowane z
natywnymi aplikacjami Linux. Nieaktywne funkcje mają pozostać ukryte.
Menu ustawień nie może udawać, że zmieniło ustawienie, jeśli nie wywołało
odpowiedniej usługi systemowej.

## Budowanie pakietu

W środowisku Arch Linux ARM zgodnym z przypiętą bazą FP4:

    cd pkgbuilds/zamarteos-shell
    makepkg -si

## Integracja

Skrypt scripts/apply-zamarteos-overlay.sh instaluje powłokę i kieruje
uruchomienie tty1 do sesji ZamarteOS. Pozostawia techniczne usługi i
sprzętową bazę FP4. Nie flashuje telefonu.

## Testowanie

Najpierw sprawdzić pakiet, obraz referencyjny, logi i weryfikator CI.
Następnie przeprowadzić testy na fizycznym FP4: start, blokada, dotyk,
przewijanie, klawiatura polska, uruchamianie aplikacji, połączenia,
dźwięk rozmów, SMS, sieć, aparat, bateria i uśpienie.

Obraz nie jest gotowy do flashowania tylko dlatego, że CI zbudowało pakiet
lub przeszły kontrole statyczne. Flashowanie wymaga osobnej decyzji.
