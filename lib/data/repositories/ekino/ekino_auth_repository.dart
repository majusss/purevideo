import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purevideo/core/services/webview_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/ekino/ekino_dio_factory.dart';
import 'package:purevideo/core/services/secure_storage_service.dart';
import 'package:purevideo/di/injection_container.dart';

class EkinoAuthRepository implements AuthRepository {
  late Dio _dio;
  AccountModel? _account;
  final _authController = StreamController<AuthModel>.broadcast();

  EkinoAuthRepository([AccountModel? account]) {
    _loadSavedAccount();
    _authController.stream.listen(_onAuthChanged);
  }

  Future<void> _loadSavedAccount() async {
    try {
      final accountJson = await SecureStorageService.getServiceData(
        SupportedService.ekino,
        'account',
      );

      if (accountJson != null) {
        _account = AccountModel.fromMap(jsonDecode(accountJson));
        _dio = EkinoDioFactory.getDio(_account);

        try {
          await _dio.get('/');
          _authController.add(
            AuthModel(
              service: SupportedService.ekino,
              success: true,
              account: _account,
            ),
          );
        } catch (e) {
          await SecureStorageService.deleteServiceData(
            SupportedService.ekino,
            'account',
          );
          _account = null;
          _dio = EkinoDioFactory.getDio(null);
        }
      } else {
        _dio = EkinoDioFactory.getDio(null);
      }
    } catch (e) {
      debugPrint('Błąd podczas ładowania konta Ekino: $e');
      _dio = EkinoDioFactory.getDio(null);
    }
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.ekino) {
      _dio = EkinoDioFactory.getDio(auth.account);
    }
  }

  @override
  Stream<AuthModel> get authStream => _authController.stream;

  String _getEkinoLoginScript(String login, String password) {
    return '''
      (function() {
        function waitForElement(selector, callback) {
          const element = document.querySelector(selector);
          if (element) {
            callback(element);
          } else {
            setTimeout(() => waitForElement(selector, callback), 100);
          }
        }
        waitForElement('.alert.alert-success', function(element) {
          window.flutter_inappwebview.callHandler('messageHandler', JSON.stringify({success: true, cookies: document.cookie}));
        });
        waitForElement('.alert.alert-danger', function(element) {
          window.flutter_inappwebview.callHandler('messageHandler', JSON.stringify({success: false, error: element.textContent.trim()}));
        });
        waitForElement('#login_fr', function(element) {
          document.forms['login_fr'].login.value = '$login';
          document.forms['login_fr'].password.value = '$password';
          document.forms['login_fr'].querySelector("input[type='submit']").click();
          // window.flutter_inappwebview.callHandler('messageHandler', element.outerHTML);
        });
        setTimeout(() => {
          window.flutter_inappwebview.callHandler('messageHandler', null, 'timeout');
        }, 15000);
      })();
    ''';
  }

  @override
  Future<AuthModel> signIn(
    Map<String, String> fields,
  ) async {
    try {
      if (fields.containsKey('anonymous')) {
        final reponse = await _dio.get(
          '/',
        );
        if (reponse.headers['set-cookie'] != null) {
          final cookies = reponse.headers['set-cookie']!
              .map((cookie) => cookie.split(';').first)
              .toList();
          debugPrint(cookies.toString());
          _account = AccountModel(
            fields: {
              'login': 'Gość',
            },
            cookies: cookies,
            service: SupportedService.ekino,
          );
          final authModel = AuthModel(
            service: SupportedService.ekino,
            success: true,
            account: _account,
          );
          _authController.add(authModel);
          return authModel;
        }
        final authModel = AuthModel(
          service: SupportedService.ekino,
          success: false,
          error: ['Nie udało się zalogować jako gość'],
        );
        _authController.add(authModel);
        return authModel;
      }

      final webviewLogin = await getIt<WebViewService>().executeJavaScript(
          '${SupportedService.ekino.baseUrl}/login',
          _getEkinoLoginScript(fields['login']!, fields['password']!));

      try {
        final json = jsonDecode(webviewLogin!);
        if (json['success'] == true && json['cookies'] != null) {
          final cookies = (json['cookies'] as String).split(';').toList();

          debugPrint('Zalogowano pomyślnie: $cookies');

          _account = AccountModel(
            fields: fields,
            cookies: cookies,
            service: SupportedService.ekino,
          );

          final authModel = AuthModel(
            service: SupportedService.ekino,
            success: true,
            account: _account,
          );
          _authController.add(authModel);
          return authModel;
        } else {
          final authModel = AuthModel(
            service: SupportedService.ekino,
            success: false,
            error: [json['error'] ?? 'Nieznany błąd logowania $webviewLogin'],
          );
          _authController.add(authModel);
          return authModel;
        }
      } catch (e) {
        debugPrint('Błąd parsowania odpowiedzi logowania: $e');

        final authModel = AuthModel(
          service: SupportedService.ekino,
          success: false,
          error: ['Błąd parsowania odpowiedzi logowania: $e'],
        );
        _authController.add(authModel);
        return authModel;
      }
    } catch (e) {
      final authModel = AuthModel(
        service: SupportedService.ekino,
        success: false,
        error: ['Błąd logowania: $e'],
      );
      _authController.add(authModel);
      return authModel;
    }
  }

  @override
  AccountModel? getAccount() {
    return _account;
  }

  @override
  Future<void> signOut() async {
    _account = null;
    _dio = EkinoDioFactory.getDio(null);
    _authController.add(
      AuthModel(
        service: SupportedService.ekino,
        success: false,
        account: null,
      ),
    );
    await SecureStorageService.deleteServiceData(
      SupportedService.ekino,
      'account',
    );
  }
}
