import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/core/utils/global_context.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/settings/screens/about_screen.dart';
import 'package:purevideo/presentation/global/screens/main_screen.dart';
import 'package:purevideo/presentation/movies/screens/home_screen.dart';
import 'package:purevideo/presentation/search/screens/search_screen.dart';
import 'package:purevideo/presentation/categories/screens/categories_screen.dart';
import 'package:purevideo/presentation/my_list/screens/my_list_screen.dart';
import 'package:purevideo/presentation/settings/screens/settings_screen.dart';
import 'package:purevideo/presentation/accounts/screens/accounts_screen.dart';
import 'package:purevideo/presentation/accounts/screens/login_screen.dart';
import 'package:purevideo/presentation/movie_details/screens/movie_details_screen.dart';
import 'package:purevideo/presentation/player/screens/player_screen.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/presentation/settings/screens/theme_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  navigatorKey: getIt<GlobalContext>().globalNavigatorKey,
  routes: [
    GoRoute(
      path: '/login/:service',
      name: 'login',
      pageBuilder: (context, state) {
        final service = state.pathParameters['service']!;
        return NoTransitionPage(
          child: LoginScreen(
            service: SupportedService.values.firstWhere(
              (e) => e.name == service,
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
      path: '/settings/theme',
      name: 'theme',
      pageBuilder: (context, state) {
        return const NoTransitionPage(child: ThemeScreen());
      },
    ),
    GoRoute(
      path: '/settings/about',
      name: 'about',
      pageBuilder: (context, state) {
        return const NoTransitionPage(child: AboutScreen());
      },
    ),
    GoRoute(
      path: '/movie/:title',
      name: 'movie_details',
      pageBuilder: (context, state) {
        return NoTransitionPage(
          child: MovieDetailsScreen(
            movie: state.extra as MovieModel,
          ),
        );
      },
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      pageBuilder: (context, state) {
        final MovieDetailsModel movie = state.extra as MovieDetailsModel;
        final int? seasonIndex = (state.uri.queryParameters['season'] != null)
            ? int.tryParse(state.uri.queryParameters['season']!)
            : null;
        final int? episodeIndex = (state.uri.queryParameters['episode'] != null)
            ? int.tryParse(state.uri.queryParameters['episode']!)
            : null;

        return NoTransitionPage(
          child: PlayerScreen(
            key: ValueKey(
              '${movie.title}-${seasonIndex ?? 0}-${episodeIndex ?? 0}',
            ),
            movie: movie,
            seasonIndex: seasonIndex,
            episodeIndex: episodeIndex,
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
