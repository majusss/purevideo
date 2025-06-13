import 'package:go_router/go_router.dart';
import 'package:purevideo/presentation/screens/settings/about_screen.dart';
import 'package:purevideo/presentation/screens/main_screen.dart';
import 'package:purevideo/presentation/screens/home_screen.dart';
import 'package:purevideo/presentation/screens/search_screen.dart';
import 'package:purevideo/presentation/screens/categories_screen.dart';
import 'package:purevideo/presentation/screens/my_list_screen.dart';
import 'package:purevideo/presentation/screens/settings/settings_screen.dart';
import 'package:purevideo/presentation/screens/settings/accounts_screen.dart';
import 'package:purevideo/presentation/screens/settings/login_screen.dart';
import 'package:purevideo/presentation/screens/movie_details_screen.dart';
import 'package:purevideo/presentation/screens/player_screen.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/presentation/screens/settings/theme_screen.dart';

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
      path: '/movie/:service/:url',
      name: 'movie_details',
      pageBuilder: (context, state) {
        final service = SupportedService.values.firstWhere(
          (e) => e.name == state.pathParameters['service'],
          orElse: () => SupportedService.values.first,
        );
        final url = state.pathParameters['url'] ?? '';

        return NoTransitionPage(
          child: MovieDetailsScreen(
            service: service,
            url: url,
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
