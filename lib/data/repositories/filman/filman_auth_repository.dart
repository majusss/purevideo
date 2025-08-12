import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_dio_factory.dart';
import 'package:purevideo/core/services/secure_storage_service.dart';
import 'package:html/parser.dart' as html;

class FilmanAuthRepository implements AuthRepository {
  late Dio _dio;
  AccountModel? _account;
  final _authController = StreamController<AuthModel>.broadcast();

  FilmanAuthRepository([AccountModel? account]) {
    _loadSavedAccount();
    _authController.stream.listen(_onAuthChanged);
  }

  Future<void> _loadSavedAccount() async {
    try {
      final accountJson = await SecureStorageService.getServiceData(
        SupportedService.filman,
        'account',
      );

      if (accountJson != null) {
        _account = AccountModel.fromMap(jsonDecode(accountJson));
        _dio = FilmanDioFactory.getDio(_account);

        try {
          await _dio.get('/');
          _authController.add(
            AuthModel(
              service: SupportedService.filman,
              success: true,
              account: _account,
            ),
          );
        } catch (e) {
          await SecureStorageService.deleteServiceData(
            SupportedService.filman,
            'account',
          );
          _account = null;
          _dio = FilmanDioFactory.getDio(null);
        }
      } else {
        _dio = FilmanDioFactory.getDio(null);
      }
    } catch (e) {
      debugPrint('Błąd podczas ładowania konta Filman.cc: $e');
      _dio = FilmanDioFactory.getDio(null);
    }
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.filman) {
      _dio = FilmanDioFactory.getDio(auth.account);
    }
  }

  @override
  Stream<AuthModel> get authStream => _authController.stream;

  @override
  Future<AuthModel> signIn(
    Map<String, String> fields,
  ) async {
    try {
      fields['submit'] = '';

      final response = await _dio.post(
        '/logowanie',
        data: fields,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      final document = html.parse(response.data);
      if (document.querySelector('.alert') != null) {
        final authModel = AuthModel(
          service: SupportedService.filman,
          success: false,
          error: [document.querySelector('.alert')!.text],
        );
        _authController.add(authModel);
        return authModel;
      }
      final cookiesHeader = response.headers['set-cookie'];
      if (cookiesHeader != null) {
        _account = AccountModel(
          fields: fields,
          cookies: cookiesHeader,
          service: SupportedService.filman,
        );

        final authModel = AuthModel(
          service: SupportedService.filman,
          success: true,
          account: _account,
        );
        _authController.add(authModel);
        return authModel;
      }
      final authModel = AuthModel(
        service: SupportedService.filman,
        success: false,
        error: ['Brak ciasteczek'],
      );
      _authController.add(authModel);
      return authModel;
    } catch (e) {
      final authModel = AuthModel(
        service: SupportedService.filman,
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
  Future<void> setAccount(AccountModel account) async {
    _account = account;
    _dio = FilmanDioFactory.getDio(_account);

    await SecureStorageService.saveServiceData(
      SupportedService.filman,
      'account',
      jsonEncode(account.toMap()),
    );

    _authController.add(
      AuthModel(
        service: SupportedService.filman,
        success: true,
        account: _account,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    _account = null;
    _dio = FilmanDioFactory.getDio(null);
    _authController.add(
      AuthModel(
        service: SupportedService.filman,
        success: false,
        account: null,
      ),
    );
    await SecureStorageService.deleteServiceData(
      SupportedService.filman,
      'account',
    );
  }
}
