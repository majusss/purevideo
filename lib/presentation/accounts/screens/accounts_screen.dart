import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/presentation/accounts/bloc/accounts_bloc.dart';
import 'package:purevideo/presentation/accounts/bloc/accounts_event.dart';
import 'package:purevideo/presentation/accounts/bloc/accounts_state.dart';
import 'package:purevideo/presentation/global/widgets/error_view.dart';
import 'package:go_router/go_router.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konta')),
      body: BlocBuilder<AccountsBloc, AccountsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: SupportedService.values.length,
                    itemBuilder: (context, index) {
                      final service = SupportedService.values[index];
                      final isLoggedIn = state.accounts.containsKey(service);

                      if (isLoggedIn) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => context.pushNamed(
                            'login',
                            pathParameters: {'service': service.name},
                          ),
                          child: Card(
                            child: ListTile(
                              leading: SizedBox(
                                width: 32,
                                height: 32,
                                child: FastCachedImage(url: service.image),
                              ),
                              title: Text(service.displayName),
                              trailing: const Icon(Icons.login),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      if (state is AccountsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is AccountsError) {
                        return ErrorView(
                          message: state.message,
                          onRetry: () {
                            context.read<AccountsBloc>().add(
                                  const LoadAccountsRequested(),
                                );
                          },
                        );
                      }
                      if (state is AccountsLoaded) {
                        if (state.accounts.isEmpty) {
                          return const Center(
                            child: Text(
                              'Brak kont. Dodaj konto używając przycisków powyżej.',
                            ),
                          );
                        }
                        return Column(
                          children: state.accounts.entries.map((account) {
                            return ListTile(
                              leading: SizedBox(
                                height: 32,
                                width: 64,
                                child: FastCachedImage(url: account.key.image),
                              ),
                              title: Text(account.value.fields.entries
                                  .firstWhere(
                                      (element) =>
                                          element.key == 'login' ||
                                          element.key == 'email',
                                      orElse: () =>
                                          const MapEntry('login', 'Unknown'))
                                  .value),
                              subtitle: Text(account.key.displayName),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  context.read<AccountsBloc>().add(
                                        SignOutRequested(account.key),
                                      );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }
                      return const Center(
                        child: Text('Nieoczekiwany błąd. Spróbuj ponownie.'),
                      );
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
