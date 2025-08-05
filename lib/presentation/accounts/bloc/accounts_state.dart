import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';

abstract class AccountsState {
  final Map<SupportedService, AccountModel> _accounts;

  const AccountsState(this._accounts);

  Map<SupportedService, AccountModel> get accounts => _accounts;
}

class AccountsLoading extends AccountsState {
  const AccountsLoading(super._accounts);
}

class AccountsLoaded extends AccountsState {
  const AccountsLoaded(super._accounts);
}

class AccountsError extends AccountsState {
  final String message;

  AccountsError(this.message) : super({});
}
