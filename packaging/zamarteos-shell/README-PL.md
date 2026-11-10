# Powłoka ZamarteOS Pure — etap 0.1.1

To jest własna powłoka Quickshell/QML dla obrazu testowego Fairphone 4.
Nie uruchamia osobnej sesji obok Moarchy: zastępuje wyłącznie program powłoki,
pozostawiając kernel, sterowniki, modem i usługi sprzętowe z bazy FP4.

## Funkcje prototypu
- ekran główny z dużym zegarem i datą;
- kafelki Telefon, Wiadomości, Aparat i Pliki;
- szuflada aplikacji oparta na zainstalowanych plikach .desktop;
- wyszukiwanie aplikacji i ich ikon;
- pasek ZamarteOS dostępny nad uruchomionymi oknami;
- centrum telefonu z odnośnikami do ustawień;
- blokada sesji Wayland przez WlSessionLock;
- sprawdzanie hasła konta przez PAM i osobny profil /etc/pam.d/zamarteos-lock.

## Budowanie pakietu

W środowisku Arch Linux ARM z repozytoriami używanymi przez obraz FP4:

    cd pkgbuilds/zamarteos-shell
    makepkg -si

## Integracja z bazą FP4

W CI skrypt scripts/apply-zamarteos-overlay.sh:
- kopiuje pakiet do pkgbuilds/;
- dodaje zamarteos-shell do zależności moarchy-meta;
- kieruje istniejący start powłoki na katalog /usr/share/zamarteos-shell;
- kieruje moarchy-lock do IPC nowej powłoki.

Nie zmienia konfiguracji modemu, kernela ani firmware. Nie flashuje telefonu.

## Testowanie

Najpierw uruchom powłokę w istniejącej sesji Wayland:

    qs -n -p /usr/share/zamarteos-shell

Nie uruchamiaj tego polecenia na obecnym Ubuntu Touch — pakiet jest budowany
dla Arch Linux ARM / bazy FP4, a nie dla Ubuntu Touch.

Blokada wymaga działającego PAM, aktywnej sesji Quickshell i hasła użytkownika.
Nie instaluj obrazu na telefonie, dopóki CI nie zbuduje pakietu i obrazu
referencyjnego, a blokada nie przejdzie testu na urządzeniu.

To nadal prototyp. Nie jest wydaniem ZamarteOS i nie jest obecnie obrazem
gotowym do flashowania.
