import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_dio_factory.dart';
import 'package:purevideo/core/services/secure_storage_service.dart';

class ObejrzyjtoAuthRepository implements AuthRepository {
  late Dio _dio;
  AccountModel? _account;
  final _authController = StreamController<AuthModel>.broadcast();

  ObejrzyjtoAuthRepository([AccountModel? account]) {
    _loadSavedAccount();
    _authController.stream.listen(_onAuthChanged);
  }

  Future<void> _loadSavedAccount() async {
    try {
      final accountJson = await SecureStorageService.getServiceData(
        SupportedService.obejrzyjto,
        'account',
      );

      if (accountJson != null) {
        _account = AccountModel.fromMap(jsonDecode(accountJson));
        _dio = ObejrzyjtoDioFactory.getDio(_account);

        try {
          await _dio.get('/');
          _authController.add(
            AuthModel(
              service: SupportedService.obejrzyjto,
              success: true,
              account: _account,
            ),
          );
        } catch (e) {
          await SecureStorageService.deleteServiceData(
            SupportedService.obejrzyjto,
            'account',
          );
          _account = null;
          _dio = ObejrzyjtoDioFactory.getDio(null);
          debugPrint(e.toString());
        }
      } else {
        _dio = ObejrzyjtoDioFactory.getDio(null);
      }
    } catch (e) {
      debugPrint('Błąd podczas ładowania konta Obejrzyj.to: $e');
      _dio = ObejrzyjtoDioFactory.getDio(null);
    }
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.obejrzyjto) {
      _dio = ObejrzyjtoDioFactory.getDio(auth.account);
    }
  }

  @override
  Stream<AuthModel> get authStream => _authController.stream;

  @override
  Future<AuthModel> signIn(
    Map<String, String> fields,
  ) async {
    try {
      if (fields.containsKey('anonymous')) {
        _account = AccountModel(
          fields: {
            'login': 'Gość',
          },
          cookies: [],
          service: SupportedService.obejrzyjto,
        );
        final authModel = AuthModel(
          service: SupportedService.obejrzyjto,
          success: true,
          account: _account,
        );
        _authController.add(authModel);
        return authModel;
      }

      final response = await _dio.post(
        '/auth/login',
        data: fields,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
        ),
      );

      if (response.data['errors'] != null) {
        final Map<String, dynamic> errors = response.data['errors'];
        final List<String> errorMessages =
            List.from(errors.values.expand((e) => e).toList());
        final authModel = AuthModel(
          service: SupportedService.obejrzyjto,
          success: false,
          error: errorMessages,
        );
        _authController.add(authModel);
        return authModel;
      }

      final cookiesHeader = response.headers["set-cookie"];

      if (cookiesHeader != null) {
        _account = AccountModel(
          fields: fields,
          cookies: cookiesHeader,
          service: SupportedService.obejrzyjto,
        );
        final authModel = AuthModel(
          service: SupportedService.obejrzyjto,
          success: true,
          account: _account,
        );
        _authController.add(authModel);
        return authModel;
      }
      final authModel = AuthModel(
        service: SupportedService.obejrzyjto,
        success: false,
        error: ['Brak ciasteczek'],
      );
      _authController.add(authModel);
      return authModel;
    } catch (e) {
      final authModel = AuthModel(
        service: SupportedService.obejrzyjto,
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
    _dio = ObejrzyjtoDioFactory.getDio(null);
    _authController.add(
      AuthModel(
        service: SupportedService.obejrzyjto,
        success: false,
        account: null,
      ),
    );
    await SecureStorageService.deleteServiceData(
      SupportedService.obejrzyjto,
      'account',
    );
  }
}
