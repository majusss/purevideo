import 'package:purevideo/core/utils/supported_enum.dart';

abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class VideoScrapingException extends AppException {
  final String url;

  const VideoScrapingException(this.url, [String? message])
      : super(message ?? 'Nie udało się pobrać źródła wideo: $url');
}

class UnsupportedHostException extends AppException {
  final String url;

  UnsupportedHostException(this.url)
      : super('Nieobsługiwany host wideo: ${Uri.tryParse(url)?.host ?? url}');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Wymagane zalogowanie się');
}

class VideoUnavailableException extends AppException {
  const VideoUnavailableException() : super('Wideo nie jest dostępne');
}

class ServiceExeption extends AppException {
  final SupportedService service;

  ServiceExeption(this.service, [String? message])
      : super(message != null
            ? 'Błąd serwisu ${service.name}: $message'
            : 'Błąd serwisu ${service.name}');
}
