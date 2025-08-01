import 'package:purevideo/core/utils/supported_enum.dart';

abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Wymagane zalogowanie się');
}

class ServiceExeption extends AppException {
  final SupportedService service;

  ServiceExeption(this.service, [String? message])
      : super(message != null
            ? 'Błąd serwisu ${service.name}: $message'
            : 'Błąd serwisu ${service.name}');
}
