# PureVideo

[![wakatime](https://wakatime.com/badge/user/63d00a78-aaef-4163-98f0-5695127e3103/project/217fcaa6-ea6b-4a0b-8ef1-68a43f879a6c.svg?style=for-the-badge)](https://wakatime.com/badge/user/63d00a78-aaef-4163-98f0-5695127e3103/project/217fcaa6-ea6b-4a0b-8ef1-68a43f879a6c)
[![Discord](https://dcbadge.limes.pink/api/server/https://discord.gg/vjtkqAMQdn)](https://discord.gg/vjtkqAMQdn) [![Build Status](https://app.bitrise.io/app/ad1d5670-9333-4ebe-af79-7113a7b0aa20/status.svg?token=6jv9x_7aMeUeZMO5L_pPTg&branch=master)](https://app.bitrise.io/app/ad1d5670-9333-4ebe-af79-7113a7b0aa20)

## Opis

**PureVideo** to wieloplatformowa aplikacja mobilna do streamingu filmów i seriali, zbudowana w oparciu o Flutter. Agreguje treści z różnych serwisów internetowych, umożliwiając wygodne przeglądanie, oglądanie oraz śledzenie postępów oglądania.

## Najważniejsze funkcje

- 🎬 Integracja z wieloma źródłami filmów i seriali (filman.cc, obejrzyj.to)
- 👤 Obsługa kont użytkowników z bezpieczną autoryzacją
- ▶️ Zaawansowany odtwarzacz wideo z zapamiętywaniem postępu oglądania
- 📊 System śledzenia obejrzanych materiałów (filmy i odcinki)
- 🖼️ Optymalizacja obrazów z szybkim cache'owaniem
- 📈 Integracja z Firebase Analytics i Crashlytics
- 🎨 Nowoczesny interfejs oparty o Material Design 3
- 🌙 Tryb ciemny i jasny z automatyczną detekcją systemu
- 🔍 Wyszukiwanie filmów i seriali
- 🚀 Aktualizacje na żywo bez instalowania nowych wersji (Shorebird)

## Architektura

### Technologie główne

- **Flutter** – framework aplikacji mobilnej (Android/iOS/Web)
- **BLoC Pattern** – zaawansowane zarządzanie stanem aplikacji
- **GetIt** – dependency injection container
- **Go Router** – nawigacja między ekranami
- **Shorebird** – aktualizacje na żywo bez przeinstalowywania aplikacji

### Bazy danych i storage

- **Hive** – szybka, lokalna baza danych NoSQL do przechowywania obejrzanych materiałów
- **Flutter Secure Storage** – bezpieczne przechowywanie danych uwierzytelniania

### Multimedia i sieć

- **MediaKit** – profesjonalny, wydajny odtwarzacz wideo z obsługą wielu formatów i protokołów streamingowych
- **Dio** – zaawansowany klient HTTP z interceptorami
- **FastCachedNetworkImage** – optymalizowane ładowanie i cachowanie obrazów

### Monitoring i analityka

- **Firebase Analytics** – analityka użytkowania
- **Firebase Crashlytics** – automatyczne raportowanie błędów
