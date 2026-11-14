# Powłoka ZamarteOS Pure — etap 0.1.1

To jest własna powłoka Quickshell/QML i sesja Wayland dla obrazu testowego
Fairphone 4. Sesja zastępuje uruchamianie powłoki Moarchy/Omarchy na tty1,
pozostawiając kernel, sterowniki, modem i usługi sprzętowe z bazy FP4.

## Funkcje prototypu
- ekran główny z dużym zegarem i datą;
- kafelki Telefon, Wiadomości, Aparat i Pliki;
- szuflada aplikacji oparta na zainstalowanych plikach .desktop;
- wyszukiwanie aplikacji i ich ikon;
- pasek ZamarteOS dostępny nad uruchomionymi oknami;
- centrum telefonu z polskim menu: sieć, dźwięk, wyświetlacz i tapety, bateria, aplikacje, prywatność, język oraz informacje o systemie;
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

To nadal prototyp. CI ma sprawdzać, czy obraz uruchamia własną sesję
ZamarteOS zamiast natywnej powłoki Moarchy. Nie jest to jeszcze wydanie
ZamarteOS ani obraz gotowy do flashowania; potrzebne są testy na fizycznym FP4.

## Klawiatura ekranowa — polskie znaki

Obraz używa osobnego klienta klawiatury ekranowej Wayland (moarchy-keyboard),
który ZamarteOS rozszerza o polski układ i lokalne sugestie pisowni.
Znaki ą ć ę ł ń ó ś ź ż oraz wielkie Ą Ć Ę Ł Ń Ó Ś Ź Ż są dostępne
po przytrzymaniu odpowiednich klawiszy literowych. Układ jest instalowany
do `/etc/skel/.config/moarchy-keyboard/layouts/letters.json`, więc trafia
do katalogu domowego podczas tworzenia konta w obrazie.

Podczas wpisywania błędnego słowa klawiatura może pokazać do trzech propozycji
korekty z lokalnego słownika Hunspell. Nie zastępuje tekstu automatycznie.
Pasek nie pokazuje się w polach haseł/PIN-u, terminalu ani polach numerycznych.
To pierwsza wersja korekty pisowni; przewidywanie następnego słowa na podstawie
kontekstu rozmowy nie jest jeszcze zaimplementowane.

Test akceptacyjny na telefonie: otworzyć pole tekstowe w Wiadomościach,
przytrzymać kolejno a, c, e, l, n, o, s i z, wybrać polskie warianty,
wpisać „Zażółć gęślą jaźń” oraz wersję z wielkimi literami, a następnie
sprawdzić, czy tekst trafia poprawnie do aplikacji. To nie jest jeszcze
potwierdzony test sprzętowy — CI sprawdza obecność i poprawność pliku układu.
