import 'package:dio/dio.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_dio_factory.dart';
import 'package:html/parser.dart' as html;

class FilmanAuthRepository implements AuthRepository {
  final Dio _dio;
  AccountModel? _account;

  FilmanAuthRepository([this._account])
    : _dio = FilmanDioFactory.getDio(_account);

  @override
  Future<AuthModel> signIn(
    String email,
    String password,
    String captcha,
  ) async {
    try {
      final response = await _dio.post(
        '/logowanie',
        data: {
          'login': email,
          'password': password,
          'submit': '',
          'g-recaptcha-response': captcha,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      final document = html.parse(response.data);
      if (document.querySelector(".alert") != null) {
        return AuthModel(
          service: SupportedService.filman,
          success: false,
          error: [document.querySelector(".alert")!.text],
        );
      }
      final cookiesHeader = response.headers["set-cookie"];
      if (cookiesHeader != null) {
        _account = AccountModel(
          login: email,
          password: password,
          cookies: cookiesHeader,
          service: SupportedService.filman,
        );
        return AuthModel(
          service: SupportedService.filman,
          success: true,
          account: _account,
        );
      }
      return AuthModel(
        service: SupportedService.filman,
        success: false,
        error: ['Brak ciasteczek'],
      );
    } catch (e) {
      if (e is DioException) {
        return AuthModel(
          service: SupportedService.filman,
          success: false,
          error: e.response?.data['error'],
        );
      }
      return AuthModel(
        service: SupportedService.filman,
        success: false,
        error: ['Błąd logowania: $e'],
      );
    }
  }

  @override
  AccountModel? getAccountForService(SupportedService service) {
    return _account;
  }

  @override
  Future<bool> isSessionValid(AccountModel account) {
    throw UnimplementedError();
  }

  @override
  Future<AuthModel> restoreSession(AccountModel account) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut(AccountModel account) {
    throw UnimplementedError();
  }
}
