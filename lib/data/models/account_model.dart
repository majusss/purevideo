import 'dart:io';

import 'package:purevideo/core/utils/supported_enum.dart';

class AccountModel {
  final Map<String, String> fields;
  final List<Cookie> cookies;
  final SupportedService service;

  AccountModel({
    required this.fields,
    required this.cookies,
    required this.service,
  });

  factory AccountModel.fromMap(Map<String, dynamic> json) {
    return AccountModel(
      fields: (json['fields'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      cookies: (json['cookies'] as List<dynamic>)
          .map((e) => Cookie.fromSetCookieValue(e.toString()))
          .toList(),
      service: SupportedService.values.byName(json['service'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fields': fields,
      'cookies': cookies.map((cookie) => cookie.toString()).toList(),
      'service': service.name,
    };
  }
}
