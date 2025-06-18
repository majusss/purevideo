import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';

abstract class AccountsState {
  const AccountsState();

  Map<SupportedService, AccountModel> get accounts => {};
}

class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

class AccountsLoaded extends AccountsState {
  final Map<SupportedService, AccountModel> _accounts;

  const AccountsLoaded(this._accounts);

  @override
  Map<SupportedService, AccountModel> get accounts => _accounts;
}

class AccountsError extends AccountsState {
  final String message;

  const AccountsError(this.message);
}
