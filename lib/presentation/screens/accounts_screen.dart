import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_event.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_state.dart';
import 'package:go_router/go_router.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konta')),
      body: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
            ),
            itemCount: SupportedService.values.length,
            itemBuilder: (context, index) {
              final service = SupportedService.values[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap:
                      () => context.pushNamed(
                        'login',
                        pathParameters: {'service': service.toString()},
                      ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 48,
                            child: Image.network(service.image),
                          ),
                          const SizedBox(height: 8),
                          Text(service.displayName),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          Expanded(
            child: BlocBuilder<AccountsBloc, AccountsState>(
              builder: (context, state) {
                if (state is AccountsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AccountsError) {
                  return Center(child: Text(state.message));
                }
                if (state is AccountsLoaded) {
                  if (state.accounts.isEmpty) {
                    return const Center(
                      child: Text(
                        'Brak kont. Dodaj konto używając przycisków powyżej.',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.accounts.length,
                    itemBuilder: (context, index) {
                      final account = state.accounts.entries.toList()[index];

                      return ListTile(
                        leading: SizedBox(
                          height: 32,
                          child: Image.network(account.key.image),
                        ),
                        title: Text(account.value.login),
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
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
