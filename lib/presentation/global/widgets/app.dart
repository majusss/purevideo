import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/accounts/bloc/accounts_bloc.dart';
import 'package:purevideo/presentation/accounts/bloc/accounts_event.dart';
import 'package:purevideo/presentation/movies/bloc/movies_bloc.dart';
import 'package:purevideo/presentation/movies/bloc/movies_event.dart';
import 'package:purevideo/presentation/global/routes/router.dart';
import 'package:purevideo/presentation/settings/widgets/settings_listenable.dart';

class PureVideoApp extends StatelessWidget {
  final SettingsService _settingsService = getIt();

  PureVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsListenable(builder: (context, box, child) {
      return MaterialApp.router(
        title: 'PureVideo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple, brightness: Brightness.dark),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        themeMode: _settingsService.theme,
        routerConfig: router,
        builder: (context, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    getIt<AccountsBloc>()..add(const LoadAccountsRequested()),
              ),
              BlocProvider(
                create: (_) => getIt<MoviesBloc>()..add(LoadMoviesRequested()),
              ),
            ],
            child: child!,
          );
        },
      );
    });
  }
}
