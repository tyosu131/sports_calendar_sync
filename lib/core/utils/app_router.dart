import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/sign_in_screen.dart';
import '../../presentation/screens/team_detail_screen.dart';
import '../../presentation/screens/team_search_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const TeamSearchScreen(),
      ),
      GoRoute(
        path: '/team/:teamId',
        builder: (context, state) => TeamDetailScreen(
          teamId: state.pathParameters['teamId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
    ],
  );
});
