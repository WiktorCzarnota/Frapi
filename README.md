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

## Uruchomienie od zera - krok po kroku

Pelna sciezka od czystego komputera do dzialajacej aplikacji. Komendy podano dla
dwoch powlok: PowerShell (Windows) oraz Bash (Git Bash na Windows, Linux, macOS).
Same komendy Fluttera sa identyczne w obu - rozni sie glownie instalacja i
ustawianie zmiennej PATH.

### 1. Zainstaluj Git

- Windows: https://git-scm.com/download/win (zawiera tez Git Bash)
- Linux: `sudo apt install git`
- macOS: `brew install git`

Sprawdzenie: `git --version`

### 2. Sklonuj repozytorium

To samo w PowerShell i Bash (podmien adres na adres swojego repozytorium):

```
git clone https://github.com/WiktorCzarnota/frapi.git
cd frapi
```

### 3. Pobierz Flutter z internetu

Najprosciej pobrac stabilny kanal Fluttera przez Git.

PowerShell (Windows):

```powershell
git clone https://github.com/flutter/flutter.git -b stable "$HOME\flutter"
$env:Path = "$HOME\flutter\bin;$env:Path"
```

Aby PATH dzialal w kazdym nowym oknie, dodaj `%USERPROFILE%\flutter\bin` do
zmiennej srodowiskowej Path (Ustawienia Windows -> "Edytuj zmienne srodowiskowe").

Bash (Git Bash / Linux / macOS):

```bash
git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
```

Aby PATH byl trwaly, dopisz linie `export PATH=...` do `~/.bashrc` (lub `~/.zshrc`).

Alternatywa (Windows, bez Gita): pobierz gotowy ZIP ze strony
https://docs.flutter.dev/get-started/install/windows, rozpakuj np. do
`C:\src\flutter` i dodaj `C:\src\flutter\bin` do Path.

Sprawdzenie instalacji (obie powloki):

```
flutter --version
flutter doctor
```

`flutter doctor` wypisze, czego jeszcze brakuje. Do budowy na Androida potrzebny
jest Android SDK - instaluje sie go razem z Android Studio
(https://developer.android.com/studio), a licencje akceptuje komenda
`flutter doctor --android-licenses`. Do uruchomienia w przegladarce ani na Windows
desktop Android SDK nie jest potrzebny.

### 4. Pobierz zaleznosci projektu

W katalogu projektu (obie powloki):

```
flutter pub get
```

### 5. Przygotuj klucz API Groq

Klucz jest darmowy (https://console.groq.com/keys) i wymagany do funkcji AI.
Podajesz go przy uruchamianiu przez `--dart-define` (patrz krok 6 oraz sekcja
"Klucz API (Groq)" nizej).

### 6. Uruchom aplikacje

Najszybciej w przegladarce Chrome (komenda taka sama w PowerShell i Bash):

```
flutter run -d chrome --dart-define=GROQ_API_KEY=twoj_klucz
```

Windows desktop:

```
flutter run -d windows --dart-define=GROQ_API_KEY=twoj_klucz
```

Telefon z Androidem (po instalacji Android SDK i wlaczeniu debugowania USB):

```
flutter run -d <id-telefonu> --dart-define=GROQ_API_KEY=twoj_klucz
```

Liste podlaczonych urzadzen pokaze `flutter devices`. Szczegoly instalacji na
telefonie (w tym wariant z plikiem APK) sa w sekcji "Uruchomienie na telefonie".

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

