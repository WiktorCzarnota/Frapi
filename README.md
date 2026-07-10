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

## Uruchomienie - najprosciej

### Telefon (Android): gotowy plik APK

Wejdz w zakladke **Releases** tego repozytorium i pobierz `app-release.apk`.
Przenies plik na telefon i zainstaluj (zezwol na instalacje z nieznanych zrodel).
Nic nie trzeba budowac - funkcje AI dzialaja od razu.

### Komputer: przez Docker (bez instalowania Fluttera)

Potrzebujesz tylko Dockera (Windows: Docker Desktop). W katalogu projektu:

```
docker compose up --build
```

Nastepnie otworz http://localhost:8080. Skan kamera dziala w przegladarce na
`localhost`. Aby dzialaly funkcje AI, przed uruchomieniem utworz plik `.env`
z kluczem Groq (patrz nizej).

## Klucz API (Groq) - do funkcji AI

Funkcje AI (analiza, zamienniki, odczyt etykiety, podsumowanie porownania)
korzystaja z modelu Groq. Klucz jest darmowy: https://console.groq.com/keys.
Aplikacja dziala tez bez klucza (skan, wyszukiwanie, dane produktu), ale funkcje
AI zglaszaja wtedy "Brak klucza API". Klucza nie commituj do repozytorium.

Dla Dockera utworz w katalogu projektu plik `.env`:

```
GROQ_API_KEY=twoj_klucz
```

`docker compose up --build` sam go wczyta.

## Budowanie ze zrodel (Flutter)

Jesli chcesz uruchomic aplikacje bez Dockera albo zbudowac wlasny APK, potrzebny
jest Flutter 3.44.4 (stable). Ponizej dwie kompletne sciezki - wybierz swoja
powloke. Warunek wstepny: zainstalowany Git (Windows:
https://git-scm.com/download/win).

### Sciezka A - PowerShell (Windows)

```powershell
# 1. Sklonuj repozytorium
git clone https://github.com/WiktorCzarnota/Frapi.git
cd Frapi

# 2. Pobierz Flutter (stable) i dodaj do PATH biezacej sesji
git clone https://github.com/flutter/flutter.git -b stable "$HOME\flutter"
$env:Path = "$HOME\flutter\bin;$env:Path"

# 3. Zaleznosci i uruchomienie w przegladarce (wstaw swoj klucz)
flutter pub get
flutter run -d chrome --dart-define=GROQ_API_KEY=twoj_klucz
```

### Sciezka B - Bash (Git Bash / Linux / macOS)

```bash
# 1. Sklonuj repozytorium
git clone https://github.com/WiktorCzarnota/Frapi.git
cd Frapi

# 2. Pobierz Flutter (stable) i dodaj do PATH biezacej sesji
git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

# 3. Zaleznosci i uruchomienie w przegladarce (wstaw swoj klucz)
flutter pub get
flutter run -d chrome --dart-define=GROQ_API_KEY=twoj_klucz
```


## Testy i jakosc kodu

```
flutter test        # testy jednostkowe
flutter analyze     # statyczna analiza / lint
dart format .       # formatowanie
```
