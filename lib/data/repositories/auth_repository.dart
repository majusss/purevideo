import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/models/account_model.dart';

abstract class AuthRepository {
  Stream<AuthModel> get authStream;
  Future<AuthModel> signIn(String email, String password, String captcha);
  Future<AuthModel> restoreSession(AccountModel account);
  AccountModel? getAccountForService(SupportedService service);
}
