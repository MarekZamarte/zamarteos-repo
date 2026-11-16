# ZamarteOS Home — natywna aplikacja Sailfish

Niezależna aplikacja Qt Quick / Sailfish Silica dla Fairphone 4 z Sailfish OS 5.0.0.72.

## Co zawiera
- natywny ekran Silica z panelem daty i zegara odświeżanym co sekundę;
- kafelki szybkiego dostępu;
- przekazywanie standardowych schematów `tel:`, `sms:` i `https:` do obsługi przez system;
- komunikat stanu dla funkcji, których integracja wymaga potwierdzenia na urządzeniu;
- wpis aplikacji i ikonę SVG instalowane do standardowych katalogów Sailfish OS.

## Budowanie
Projekt używa qmake i biblioteki SailfishApp. Należy budować go w Sailfish SDK na celu `aarch64` zgodnym z Sailfish OS 5.0.0.72. Oficjalna dokumentacja opisuje użycie `sfdk` i wybór celu ARM64:
https://docs.sailfishos.org/Tools/Sailfish_SDK/Building_packages/

## Ograniczenia — uczciwy status
- Źródła nie zostały jeszcze skompilowane w Sailfish SDK.
- Nie wykonano testu uruchomienia na Fairphone 4.
- Telefon, wiadomości i przeglądarka korzystają ze standardowego przekazywania URL; działanie zależy od zarejestrowanych handlerów w systemie.
- Kontakty, aparat i ustawienia są na razie kafelkami informacyjnymi — ich bezpieczne uruchamianie wymaga weryfikacji rzeczywistych usług na urządzeniu.
- To nie jest zamiennik Lipstick ani kompletna powłoka systemowa.

## Bezpieczeństwo
Aplikacja nie ingeruje w Lipstick, modem, sterowniki, stos audio ani usługi telefoniczne. Nie instaluje Androida ani usług Google.
