import 'package:purevideo/core/utils/supported_enum.dart';

abstract class AccountsEvent {
  const AccountsEvent();
}

class SignInRequested extends AccountsEvent {
  final SupportedService service;
  final String email;
  final String password;
  final String captcha;

  const SignInRequested({
    required this.service,
    required this.email,
    required this.password,
    required this.captcha,
  });
}

class SignOutRequested extends AccountsEvent {
  final SupportedService service;

  const SignOutRequested(this.service);
}

class LoadAccountsRequested extends AccountsEvent {
  const LoadAccountsRequested();
}
