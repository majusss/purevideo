import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/models/account_model.dart';

abstract class AuthRepository {
  Future<AuthModel> signIn(String email, String password, String captcha);

  Future<bool> isSessionValid(AccountModel account);

  Future<AuthModel> restoreSession(AccountModel account);

  Future<void> signOut(AccountModel account);

  AccountModel? getAccountForService(SupportedService service);
}

class AuthRepositoryImpl implements AuthRepository {
  @override
  AccountModel? getAccountForService(SupportedService service) {
    throw UnimplementedError();
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
  Future<AuthModel> signIn(String email, String password, String captcha) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut(AccountModel account) {
    throw UnimplementedError();
  }
}
