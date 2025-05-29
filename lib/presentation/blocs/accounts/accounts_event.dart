import 'package:purevideo/core/utils/supported_enum.dart';

abstract class AccountsEvent {
  const AccountsEvent();
}

class SignInRequested extends AccountsEvent {
  final SupportedService service;
  final Map<String, String> fields;

  const SignInRequested({
    required this.service,
    required this.fields,
  });
}

class SignOutRequested extends AccountsEvent {
  final SupportedService service;

  const SignOutRequested(this.service);
}

class LoadAccountsRequested extends AccountsEvent {
  const LoadAccountsRequested();
}
