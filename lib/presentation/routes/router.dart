import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/presentation/screens/main_screen.dart';
import 'package:purevideo/presentation/screens/home_screen.dart';
import 'package:purevideo/presentation/screens/search_screen.dart';
import 'package:purevideo/presentation/screens/categories_screen.dart';
import 'package:purevideo/presentation/screens/my_list_screen.dart';
import 'package:purevideo/presentation/screens/settings_screen.dart';
import 'package:purevideo/presentation/screens/accounts_screen.dart';
import 'package:purevideo/presentation/screens/login_screen.dart';
import 'package:purevideo/presentation/screens/movie_details_screen.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/widgets/error_view.dart';

final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/login/:service',
      name: 'login',
      pageBuilder: (context, state) {
        final service = state.pathParameters['service']!;
        return NoTransitionPage(
          child: LoginScreen(
            service: SupportedService.values.firstWhere(
              (e) => e.toString() == service,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/settings/accounts',
      name: 'accounts',
      pageBuilder: (context, state) {
        return const NoTransitionPage(child: AccountsScreen());
      },
    ),
    GoRoute(
      path: '/movie/:service/:url',
      name: 'movie_details',
      pageBuilder: (context, state) {
        final service = SupportedService.values.firstWhere(
          (e) => e.name == state.pathParameters['service'],
        );
        final url = state.pathParameters['url']!;
        final repository =
            getIt<Map<SupportedService, MovieRepository>>()[service]!;

        return NoTransitionPage(
          child: FutureBuilder(
            future: repository.getMovieDetails(url),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return MovieDetailsScreen(movie: snapshot.data!);
              }
              if (snapshot.hasError) {
                return Scaffold(
                  appBar: AppBar(
                    leading: BackButton(onPressed: () => context.pop()),
                  ),
                  body: ErrorView(
                    message: 'Wystąpił błąd: ${snapshot.error}',
                    onRetry: () {
                      context.goNamed(
                        'movie_details',
                        pathParameters: {'service': service.name, 'url': url},
                      );
                    },
                  ),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: HomeScreen());
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: SearchScreen());
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              name: 'categories',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: CategoriesScreen());
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my-list',
              name: 'my-list',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: MyListScreen());
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: SettingsScreen());
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
