# frapi - aplikacja wspomagajaca swiadome zakupy spozywcze

Aplikacja mobilna (Flutter) wspierajaca swiadome zakupy spozywcze. Powstaje jako
projekt do pracy licencjackiej: *"Projekt i implementacja aplikacji mobilnej
wspomagajacej swiadome zakupy spozywcze"*.

Wspolny przeplyw wszystkich funkcji:

```
skan kodu / wyszukanie / zdjecie etykiety
  -> dane produktu (Open Food Facts)
  -> analiza przez LLM (Groq)
  -> czytelna rekomendacja pod profil uzytkownika
```

## Funkcje

- Skaner kodu kreskowego kamera (`mobile_scanner`) oraz wpisanie kodu recznie.
- Wyszukiwanie produktow po nazwie (Open Food Facts).
- Dodanie produktu spoza bazy ze zdjecia etykiety (LLM z wizja odczytuje dane).
- Analiza skladu i ocena dopasowania do profilu uzytkownika (LLM).
- Zdrowsze zamienniki (klikalne, prowadza do wyszukiwarki).
- Profil uzytkownika: skladniki zakazane / niechciane / zalecane, cel oraz
  preferencje wartosci odzywczych (mniej / obojetnie / wiecej).
- Historia skanow oraz porownywarka do 6 produktow (paski, kolory, sortowanie,
  krotkie podsumowanie AI).

## Wymagania

- Flutter 3.44.4 (stable), Dart 3.12.2.
- Darmowy klucz API Groq (patrz nizej).
- Do testow na Androidzie: Android SDK (instalowane wraz z Android Studio).

## Klucz API (Groq) - wymagany do funkcji AI

Funkcje AI (analiza, zamienniki, odczyt etykiety, podsumowanie porownania)
wymagaja klucza Groq. Klucz jest darmowy i dziala w Polsce bez karty.

1. Zaloz konto i wygeneruj klucz: https://console.groq.com/keys
2. Klucz podajesz przy uruchomieniu przez `--dart-define=GROQ_API_KEY=...`.

WAZNE: klucza nie umieszczaj w kodzie ani w repozytorium. Podawaj go tylko w
komendzie uruchomieniowej. Bez klucza aplikacja dziala (skan, wyszukiwanie,
dane produktu), ale funkcje AI zglaszaja "Brak klucza API".

## Pobranie zaleznosci

```
flutter pub get
```

## Uruchomienie na komputerze

Najszybciej do testow - przegladarka Chrome:

```
flutter run -d chrome --dart-define=GROQ_API_KEY=twoj_klucz
```

Windows desktop:

```
flutter run -d windows --dart-define=GROQ_API_KEY=twoj_klucz
```

Uwagi:
- Skan kamera nie dziala na Windows desktop (plugin nie wspiera tej platformy) -
  do testow skanu uzyj Chrome (localhost) lub telefonu. Reszta funkcji dziala.
- W trakcie dzialania: `r` = hot reload, `R` = hot restart, `q` = wyjscie.

## Uruchomienie na telefonie (Android)

### Wariant 1: przez USB (z hot reload)

1. Zainstaluj Android Studio (dociaga Android SDK) i zaakceptuj licencje:
   ```
   flutter doctor --android-licenses
   ```
2. W telefonie wlacz Opcje programistyczne (7x stuknij "Numer kompilacji")
   i wlacz "Debugowanie USB".
3. Podlacz telefon kablem, na telefonie zezwol na debugowanie USB.
4. Sprawdz i uruchom:
   ```
   flutter devices
   flutter run -d <id-telefonu> --dart-define=GROQ_API_KEY=twoj_klucz
   ```

### Wariant 2: plik APK (gdy USB-install jest zablokowany, np. MIUI/Xiaomi bez SIM)

1. Zbuduj APK z kluczem:
   ```
   flutter build apk --release --dart-define=GROQ_API_KEY=twoj_klucz
   ```
2. Plik powstanie w `build/app/outputs/flutter-apk/app-release.apk`.
3. Przerzuc go na telefon (kabel w trybie MTP albo Dysk Google) i zainstaluj,
   zezwalajac menedzerowi plikow na instalacje z nieznanych zrodel.
4. Kolejne aktualizacje: ten sam build nadpisuje plik; instalacja "na wierzch"
   zachowuje dane (profil, historia).

Przy pierwszym uruchomieniu aplikacja poprosi o zgode na aparat (skan kodu,
zdjecie etykiety).

## Testy i jakosc kodu

```
flutter test        # testy jednostkowe
flutter analyze     # statyczna analiza / lint
dart format .       # formatowanie
```

## Znane ograniczenia

- Klucz API w aplikacji mobilnej nie jest w pelni bezpieczny; docelowo serwer
  proxy (poza zakresem MVP).
- Open Food Facts miewa niepelne dane, a polskie produkty bywaja slabo pokryte -
  stad opcja dodania produktu ze zdjecia etykiety.
- Skan kodu kamera dziala na Androidzie i w przegladarce; nie na Windows desktop.

