# Powłoka ZamarteOS Pure — etap 0.1

To jest pierwszy, samodzielny prototyp powłoki dla Quickshell.

## Co zawiera
- ekran główny z dużym zegarem i datą;
- kafelki Telefon, Wiadomości, Aparat i Pliki;
- szufladę aplikacji opartą na zainstalowanych plikach .desktop;
- wyszukiwanie aplikacji;
- ekran Centrum telefonu z odnośnikami do ustawień;
- osobną sesję Wayland uruchamianą przez Hyprland.

## Budowanie pakietu

W środowisku Arch Linux ARM z pakietami base-devel, quickshell i hyprland:

    cd packaging/zamarteos-shell
    makepkg -si

## Test bez zmiany bieżącej sesji

Najpierw uruchom powłokę wewnątrz istniejącej sesji Wayland:

    qs --path /usr/share/zamarteos-shell/shell.qml

Nie wybieraj jeszcze sesji ZamarteOS na ekranie logowania. Konfiguracja wejścia
dotykowego, klawiatury ekranowej, blokady, zasilania, modemu i usług audio nie
jest ukończona.

To prototyp UI 0.1, nie gotowy system i nie obraz do flashowania.
