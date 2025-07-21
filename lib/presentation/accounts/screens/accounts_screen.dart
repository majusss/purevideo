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
    return BlocProvider(
      create: (_) => AccountsBloc()..add(const LoadAccountsRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Konta')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: SupportedService.values.length,
                  itemBuilder: (context, index) {
                    final service = SupportedService.values[index];
                    return GestureDetector(
                      onTap: () => context.pushNamed(
                        'login',
                        pathParameters: {'service': service.toString()},
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 48,
                                child: Center(
                                  child: FastCachedImage(url: service.image),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                service.displayName,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, state) {
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
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
