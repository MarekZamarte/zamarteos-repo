# Eksperymentalny stos IMS dla Fairphone 4

## Cel

Ta gałąź bada alternatywną ścieżkę połączeń VoLTE opartą o **imsd**. Nie zastępuje ona obecnej gałęzi `zamarteos-pure-fp4-dev` i nie zmienia jej konfiguracji.

## Architektura kandydująca

- ModemManager + QMI/QRTR: dostęp do modemu, SIM i sesji danych.
- imsd: własny klient IMS/VoLTE w przestrzeni użytkownika (SIP, AKA, IPsec/ESP, sygnalizacja połączeń).
- imsd-media: media RTP (AMR-WB/AMR/G.711) przez PipeWire.
- imsd-dialerd albo imsd-ofonod: adapter do dialera; adapter ofono imsd nie może działać równocześnie z prawdziwym `ofonod`.
- GNOME Calls / własny dialer ZamarteOS: interfejs użytkownika.

**Ważne rozróżnienie:** imsd nadal używa ModemManager i QMI. Nie jest to zamiana ModemManagera na oFono. `imsd-ofonod` udostępnia zgodny interfejs D-Bus dla dialera, ale sam imsd zarządza IMS przez ModemManager.

## Dlaczego warto to sprawdzić

Obecna ścieżka Q6Voice wykorzystuje modemowy tor głosowy i wymaga poprawnego uruchomienia PCM oraz routingu ALSA/UCM. imsd ma inną architekturę: realizuje IMS i przesyła RTP przez PipeWire. To potencjalnie niezależna droga dla VoLTE, ale wymaga sprawnego wejścia mikrofonowego i wyjścia audio FP4 w PipeWire.

## Stan zgodności Fairphone 4

- Nie ma potwierdzonego testu imsd na Fairphone 4.
- Publiczne testy projektu wymieniają Fairphone 6, nie Fairphone 4.
- Dokumentacja projektu wymaga Qualcomm modem, działającej integracji WWAN/ModemManager, QRTR, IPsec ESP oraz PipeWire.
- Materiały o głównej linii kernela FP4 wskazują, że audio jest nadal istotnym problemem. Nie wolno więc zakładać, że sam imsd naprawi mikrofon lub głośnik.
- Pierwszy etap CI buduje i uruchamia testy jednostkowe imsd na ARM64. To test kompilacji i logiki, **nie test połączeń na FP4**.

## Plan walidacji

1. Zbudować upstream imsd dla ARM64 i uruchomić wszystkie testy jednostkowe.
2. Zbadać dostępność QRTR, IMS PDN, IPsec ESP i P-CSCF na bazie FP4 bez zmiany konfiguracji modemu.
3. Zweryfikować niezależnie PipeWire: mikrofon, słuchawkę, głośnik i jednoczesne wejście/wyjście.
4. Dopiero po pozytywnych testach przygotować pakiety Arch ARM i integrację z dialerem.
5. Na fizycznym FP4 wykonać połączenia wychodzące i przychodzące oraz test dwukierunkowego audio. Nie twierdzić, że działa, zanim test zostanie wykonany.

## Zasady bezpieczeństwa

- Gałąź eksperymentalna nie jest obrazem do instalacji.
- CI nie flashuje telefonu i nie zmienia modemu.
- Nie instalować równolegle `imsd-ofonod` i prawdziwego `ofonod`.
- Nie włączać równolegle dwóch menedżerów próbujących przejąć ten sam modem.
- Obecna gałąź Pure pozostaje nienaruszona.
