import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/models/account_model.dart';

abstract class AuthRepository {
  Stream<AuthModel> get authStream;
  Future<AuthModel> signIn(Map<String, String> fields);
  AccountModel? getAccount();
  Future<void> signOut();
}
