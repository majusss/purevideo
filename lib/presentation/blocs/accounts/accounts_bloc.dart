import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/core/services/secure_storage_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_event.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_state.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final Map<SupportedService, AuthRepository> _repositories = getIt();
  final Map<SupportedService, AccountModel> _accounts = {};

  AccountsBloc() : super(const AccountsInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<LoadAccountsRequested>(_onLoadAccountsRequested);
  }

  Future<AccountModel?> getAccountForService(SupportedService service) async {
    if (_accounts.containsKey(service)) {
      return _accounts[service];
    }

    final repository = _repositories[service];
    if (repository == null) {
      return null;
    }

    final account = repository.getAccountForService(service);
    if (account != null) {
      _accounts[service] = account;
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
          jsonEncode(account.toJson()),
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
      _accounts.remove(event.service);
      await SecureStorageService.deleteServiceData(event.service, 'account');
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

      debugPrint("Loading accounts");

      for (final service in _repositories.keys) {
        final account = await getAccountForService(service);
        final accountJson = await SecureStorageService.getServiceData(
          service,
          'account',
        );
        if (accountJson != null) {
          _accounts[service] = AccountModel.fromJson(jsonDecode(accountJson));
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
