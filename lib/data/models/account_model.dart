import 'package:purevideo/core/utils/supported_enum.dart';

class AccountModel {
  final String login;
  final String password;
  final List<String> cookies;
  final SupportedService service;

  AccountModel({
    required this.login,
    required this.password,
    required this.cookies,
    required this.service,
  });
}
