import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_event.dart';
import 'package:purevideo/presentation/blocs/movies/movies_bloc.dart';
import 'package:purevideo/presentation/blocs/movies/movies_event.dart';
import 'package:purevideo/presentation/routes/router.dart';

void main() {
  setupInjection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PureVideo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create:
                  (_) => getIt<AccountsBloc>()..add(LoadAccountsRequested()),
            ),
            BlocProvider(
              create: (_) => getIt<MoviesBloc>()..add(LoadMoviesRequested()),
            ),
          ],
          child: child!,
        );
      },
    );
  }
}
