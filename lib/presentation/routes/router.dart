import 'package:go_router/go_router.dart';
import 'package:purevideo/presentation/screens/main_screen.dart';
import 'package:purevideo/presentation/screens/home_screen.dart';
import 'package:purevideo/presentation/screens/search_screen.dart';
import 'package:purevideo/presentation/screens/categories_screen.dart';
import 'package:purevideo/presentation/screens/my_list_screen.dart';
import 'package:purevideo/presentation/screens/settings_screen.dart';
import 'package:purevideo/presentation/screens/accounts_screen.dart';
import 'package:purevideo/presentation/screens/login_screen.dart';
import 'package:purevideo/core/utils/supported_enum.dart';

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
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: HomeScreen());
          },
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: SearchScreen());
          },
        ),
        GoRoute(
          path: '/categories',
          name: 'categories',
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: CategoriesScreen());
          },
        ),
        GoRoute(
          path: '/my-list',
          name: 'my-list',
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: MyListScreen());
          },
        ),
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
);
