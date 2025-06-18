import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/core/services/secure_storage_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/accounts/bloc/accounts_event.dart';
import 'package:purevideo/presentation/accounts/bloc/accounts_state.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final Map<SupportedService, AuthRepository> _repositories = getIt();
  final Map<SupportedService, AccountModel> _accounts = {};

  AccountsBloc() : super(const AccountsLoading()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<LoadAccountsRequested>(_onLoadAccountsRequested);
  }

  Future<AccountModel?> getAccountForService(SupportedService service) async {
    final repository = _repositories[service];
    if (repository == null) {
      return null;
    }

    final account = repository.getAccount();
    if (account != null) {
      _accounts[service] = account;
    } else {
      _accounts.remove(service);
    }
    return account;
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      emit(const AccountsLoading());

      final repository = _repositories[event.service];
      if (repository == null) {
        throw Exception('Brak obsługi serwisu ${event.service}');
      }

      final result = await repository.signIn(event.fields);

      if (result.success && result.account != null) {
        FirebaseAnalytics.instance.logLogin(
          loginMethod: event.service.name,
        );
        final account = AccountModel(
          fields: result.account!.fields,
          cookies: result.account!.cookies,
          service: event.service,
        );
        await SecureStorageService.saveServiceData(
          event.service,
          'account',
          jsonEncode(account.toMap()),
        );
        _accounts[event.service] = account;
        emit(AccountsLoaded(Map.from(_accounts)));
      } else {
        emit(AccountsError(result.error?.first ?? 'Błąd logowania'));
      }
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      emit(const AccountsLoading());
      final repository = _repositories[event.service];
      if (repository == null) {
        emit(AccountsError('Brak obsługi serwisu ${event.service}'));
      }
      await repository?.signOut();
      _accounts.remove(event.service);
      emit(AccountsLoaded(Map.from(_accounts)));
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> _onLoadAccountsRequested(
    LoadAccountsRequested event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      emit(const AccountsLoading());

      for (final service in _repositories.keys) {
        final account = await getAccountForService(service);
        final accountJson = await SecureStorageService.getServiceData(
          service,
          'account',
        );
        if (accountJson != null) {
          _accounts[service] = AccountModel.fromMap(jsonDecode(accountJson));
        }
        if (account != null) {
          _accounts[service] = account;
        }
      }

      emit(AccountsLoaded(Map.from(_accounts)));
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }
}
