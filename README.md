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

- Git oraz Flutter 3.44.4 (stable), Dart 3.12.2 - instalacja opisana ponizej.
- Darmowy klucz API Groq (patrz nizej).
- Do budowy/testow na Androidzie: Android SDK (instalowane wraz z Android Studio).

## Klucz API (Groq) - wymagany do funkcji AI

Funkcje AI (analiza, zamienniki, odczyt etykiety, podsumowanie porownania)
wymagaja klucza Groq. Klucz jest darmowy i dziala w Polsce bez karty.

1. Zaloz konto i wygeneruj klucz: https://console.groq.com/keys
2. Klucz podajesz przy uruchomieniu przez `--dart-define=GROQ_API_KEY=...`
   (w komendach ponizej wstawiasz go zamiast `twoj_klucz`).

WAZNE: klucza nie umieszczaj w kodzie ani w repozytorium. Podawaj go tylko w
komendzie uruchomieniowej. Bez klucza aplikacja dziala (skan, wyszukiwanie,
dane produktu), ale funkcje AI zglaszaja "Brak klucza API".

## Uruchomienie od zera

Ponizej dwie kompletne, niezalezne sciezki - wybierz jedna zaleznie od powloki.
Kazda prowadzi od zera (bez zainstalowanego Fluttera) do dzialajacej aplikacji.

- Sciezka A - PowerShell (Windows)
- Sciezka B - Bash (Git Bash na Windows, Linux, macOS)

Warunek wstepny dla obu: zainstalowany Git. Windows:
https://git-scm.com/download/win (instalator zawiera tez Git Bash). Linux:
`sudo apt install git`. macOS: `brew install git`. Sprawdzenie: `git --version`.

### Sciezka A - PowerShell (Windows)

Otworz PowerShell i wykonaj po kolei:

```powershell
# 1. Sklonuj repozytorium aplikacji i wejdz do katalogu
git clone https://github.com/WiktorCzarnota/Frapi.git
cd Frapi

# 2. Pobierz Flutter (kanal stable) i dodaj do PATH biezacej sesji
git clone https://github.com/flutter/flutter.git -b stable "$HOME\flutter"
$env:Path = "$HOME\flutter\bin;$env:Path"

# 3. Sprawdz instalacje (wypisze wersje i ewentualne braki)
flutter --version
flutter doctor

# 4. Pobierz zaleznosci projektu
flutter pub get

# 5. Uruchom w przegladarce Chrome (wstaw swoj klucz Groq zamiast twoj_klucz)
flutter run -d chrome --dart-define=GROQ_API_KEY=twoj_klucz
```

Uwagi (PowerShell):
- PATH ustawiony w kroku 2 dziala tylko w biezacym oknie. Aby byl trwaly, dodaj
  `%USERPROFILE%\flutter\bin` do zmiennej srodowiskowej Path (Ustawienia Windows
  -> "Edytuj zmienne srodowiskowe systemu") i otworz nowy PowerShell.
- Windows desktop: `flutter run -d windows --dart-define=GROQ_API_KEY=twoj_klucz`
  (skan kamera nie dziala na desktopie - do testu skanu uzyj Chrome lub telefonu).
- Alternatywa bez klonowania Fluttera: pobierz ZIP ze strony
  https://docs.flutter.dev/get-started/install/windows, rozpakuj do
  `C:\src\flutter` i dodaj `C:\src\flutter\bin` do Path.

### Sciezka B - Bash (Git Bash / Linux / macOS)

Otworz terminal Bash i wykonaj po kolei:

```bash
# 1. Sklonuj repozytorium aplikacji i wejdz do katalogu
git clone https://github.com/WiktorCzarnota/Frapi.git
cd Frapi

# 2. Pobierz Flutter (kanal stable) i dodaj do PATH biezacej sesji
git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

# 3. Sprawdz instalacje (wypisze wersje i ewentualne braki)
flutter --version
flutter doctor

# 4. Pobierz zaleznosci projektu
flutter pub get

# 5. Uruchom w przegladarce Chrome (wstaw swoj klucz Groq zamiast twoj_klucz)
flutter run -d chrome --dart-define=GROQ_API_KEY=twoj_klucz
```

Uwagi (Bash):
- PATH ustawiony w kroku 2 dziala tylko w biezacej sesji. Aby byl trwaly, dopisz
  `export PATH="$HOME/flutter/bin:$PATH"` do `~/.bashrc` (lub `~/.zshrc`) i otworz
  nowy terminal.
- Windows desktop (Git Bash):
  `flutter run -d windows --dart-define=GROQ_API_KEY=twoj_klucz`.
- Na Linux/macOS `flutter doctor` moze wskazac dodatkowe zaleznosci systemowe.

## Uruchomienie na telefonie (Android)

Wymaga zainstalowanego Android SDK (dociaga je Android Studio) oraz akceptacji
licencji: `flutter doctor --android-licenses`.

### Wariant 1: przez USB (z hot reload)

1. W telefonie wlacz Opcje programistyczne (7x stuknij "Numer kompilacji")
   i wlacz "Debugowanie USB".
2. Podlacz telefon kablem, na telefonie zezwol na debugowanie USB.
3. Sprawdz i uruchom:
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
zdjecie etykiety). W trakcie dzialania: `r` = hot reload, `R` = hot restart,
`q` = wyjscie.

## Testy i jakosc kodu

```
flutter test        # testy jednostkowe
flutter analyze     # statyczna analiza / lint
dart format .       # formatowanie
```

## Sprawdzenie w Dockerze (opcjonalnie)

Docker pozwala uruchomic webowa wersje aplikacji bez instalowania Fluttera na
komputerze. Wymaga zainstalowanego Dockera (Windows: Docker Desktop). Komendy sa
takie same w PowerShell i Bash.

### Uruchomienie aplikacji (web) w kontenerze

W katalogu projektu (jest tu `Dockerfile`):

```
docker build --build-arg GROQ_API_KEY=twoj_klucz -t frapi-web .
docker run --rm -p 8080:80 frapi-web
```

Nastepnie otworz http://localhost:8080. Skan kamera dziala, bo `localhost` jest
traktowany przez przegladarke jako bezpieczny kontekst. Klucz Groq zostaje
wkompilowany w wersje web - uzywaj tego tylko lokalnie i nie publikuj obrazu.

### Sama weryfikacja kodu (testy + analiza), bez uruchamiania

PowerShell:

```powershell
docker run --rm -v "${PWD}:/app" -w /app ghcr.io/cirruslabs/flutter:3.44.4 `
  sh -c "git config --global --add safe.directory /app && flutter pub get && flutter analyze && flutter test"
```

Bash:

```bash
docker run --rm -v "$(pwd):/app" -w /app ghcr.io/cirruslabs/flutter:3.44.4 \
  sh -c "git config --global --add safe.directory /app && flutter pub get && flutter analyze && flutter test"
```

Uwaga: ta komenda montuje biezacy katalog, wiec jego sciezka nie moze zawierac
spacji - uruchamiaj ja z repozytorium sklonowanego do katalogu bez spacji
(np. `C:\frapi`).

## Znane ograniczenia

- Klucz API w aplikacji mobilnej nie jest w pelni bezpieczny; docelowo serwer
  proxy (poza zakresem MVP).
- Open Food Facts miewa niepelne dane, a polskie produkty bywaja slabo pokryte -
  stad opcja dodania produktu ze zdjecia etykiety.
- Skan kodu kamera dziala na Androidzie i w przegladarce; nie na Windows desktop.
