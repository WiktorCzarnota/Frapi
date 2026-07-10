# syntax=docker/dockerfile:1
# Budowa i uruchomienie webowej wersji aplikacji frapi w kontenerze.
# Skan kamera dziala w przegladarce na http://localhost (bezpieczny kontekst).

# Etap 1: budowa aplikacji webowej (obraz z preinstalowanym Flutterem)
FROM ghcr.io/cirruslabs/flutter:3.44.4 AS build

# Klucz Groq wstrzykiwany przy budowaniu (do funkcji AI). Bez niego aplikacja
# dziala, ale funkcje AI zglaszaja "Brak klucza API".
ARG GROQ_API_KEY=""

WORKDIR /app
COPY . .

RUN git config --global --add safe.directory /app \
    && flutter pub get \
    && flutter build web --release --dart-define=GROQ_API_KEY=$GROQ_API_KEY

# Etap 2: lekki serwer statyczny serwujacy zbudowana aplikacje
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
