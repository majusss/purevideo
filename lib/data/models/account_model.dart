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

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      login: json['login'] as String,
      password: json['password'] as String,
      cookies:
          (json['cookies'] as List<dynamic>).map((e) => e.toString()).toList(),
      service: SupportedService.values.byName(json['service'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'password': password,
      'cookies': cookies,
      'service': service.name,
    };
  }
}
