# Opis Projektu: PureVideo - Aplikacja Streamingowa we Flutterze

PureVideo to wieloplatformowa aplikacja mobilna do streamingu filmów i seriali, zbudowana przy użyciu frameworka Flutter. Projekt zakłada pozyskiwanie treści z różnych źródeł internetowych poprzez mechanizmy scrapowania, co pozwala na agregację bogatej biblioteki mediów z rozproszonych zasobów.

## Założenia projektu

Głównym celem projektu jest stworzenie kompleksowej aplikacji streamingowej, która będzie:

- Umożliwiać użytkownikom dostęp do filmów i seriali z różnych źródeł w jednym miejscu
- Zapewniać wysoką jakość odtwarzania treści multimedialnych
- Oferować intuicyjny i responsywny interfejs użytkownika
- Działać na platformach Android i iOS
- Efektywnie zarządzać zasobami urządzenia (pamięć, dane mobilne)

## Stos technologiczny

### Podstawy:

- **Flutter** - jako framework do tworzenia wieloplatformowej aplikacji
- **Dart** - język programowania
- **Clean Architecture** - jako wzorzec architektoniczny

### Kluczowe biblioteki:

- **Dio** - zaawansowany klient HTTP do komunikacji z różnymi źródłami treści i scrapowania danych
- **CachedNetworkImage** - biblioteka do efektywnego zarządzania i cachowania obrazów
- **MediaKit** - kompleksowy framework do odtwarzania materiałów wideo z akcelereacją sprzętową
- **flutter_bloc/bloc** - do zarządzania stanem aplikacji
- **Hive** - nowoczesna baza danych NoSQL do przechowywania danych lokalnie
- **get_it** - do wstrzykiwania zależności
- **go_router** - do zaawansowanej nawigacji i zarządzania routingiem

### Dodatkowe narzędzia:

- **html** - do scrapowania treści z różnych stron internetowych

## Struktura projektu

Projekt będzie zorganizowany zgodnie z zasadami Clean Architecture:

## Kluczowe funkcjonalności

### 1. Ekran główny

- Sekcje z rekomendowanymi filmami i serialami
- Kategorie treści (filmy, seriale, dokumenty)
- Karuzele z różnymi typami treści (popularne, nowe, trendy)

### 2. Wyszukiwanie i filtrowanie

- Globalne wyszukiwanie treści po tytule, gatunku, aktorach
- Filtry treści (rok produkcji, gatunek, oceny)
- Historia wyszukiwania

### 3. Szczegóły treści

- Pełne informacje o filmie/serialu
- Galeria zdjęć
- Obsada i twórcy
- Podobne treści
- Oceny i możliwość dodania do listy "Do obejrzenia"

### 4. Odtwarzacz

- Płynne odtwarzanie wideo w różnych rozdzielczościach
- Kontrola odtwarzania (pauza, przewijanie, głośność)
- Automatyczna adaptacja jakości do łącza internetowego
- Tryb pełnoekranowy i Picture-in-Picture

### 5. Zarządzanie treściami

- Lista "Do obejrzenia"
- Historia oglądania
- Ulubione treści
- Automatyczne wznawianie odtwarzania

### 6. Ustawienia

- Preferencje jakości odtwarzania
- Zarządzanie cache'em
- Wybór preferowanych źródeł treści
- Personalizacja interfejsu

## Mechanizm scrapowania

Aplikacja będzie wykorzystywać proste techniki scrapowania treści:

- **Statyczne scrapowanie** - wykorzystując Dio i HTML parser do efektywnego pozyskiwania treści
- **Mechanizm cache'owania** - aby zminimalizować liczbę zapytań do źródeł

## Przewidywane wyzwania

### Techniczne:

- Obsługa różnorodnych struktur HTML na scrapowanych stronach
- Zapewnienie stabilnego i szybkiego streamingu wideo
- Optymalizacja zużycia danych i baterii
- Obejście zabezpieczeń anty-scrapingowych

### Prawne:

- Kwestie związane z prawami autorskimi do treści
- Potencjalne naruszenie warunków użytkowania stron źródłowych
- Przechowywanie i przetwarzanie danych użytkowników zgodnie z RODO

## Harmonogram realizacji

### Faza 1: Przygotowanie projektu (2 tygodnie)

- Konfiguracja środowiska
- Instalacja i integracja podstawowych bibliotek
- Utworzenie szkieletu aplikacji zgodnie z Clean Architecture

### Faza 2: Implementacja mechanizmów scrapowania (4 tygodnie)

- Implementacja podstawowego scrapera
- Dodanie obsługi różnych źródeł
- Testowanie i optymalizacja mechanizmów scrapowania

### Faza 3: Rozwój interfejsu użytkownika (3 tygodnie)

- Implementacja głównych ekranów
- Rozwój komponentów UI
- Integracja z warstwą danych

### Faza 4: Implementacja odtwarzacza wideo (3 tygodnie)

- Integracja MediaKit
- Implementacja kontrolek odtwarzacza
- Optymalizacja odtwarzania

### Faza 5: Testowanie i optymalizacja (2 tygodnie)

- Testy wydajnościowe
- Optymalizacja zużycia zasobów
- Poprawa UX/UI

### Faza 6: Finalizacja i przygotowanie do wydania (2 tygodnie)

- Finalne poprawki
- Przygotowanie do dystrybucji
- Dokumentacja
