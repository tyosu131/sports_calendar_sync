import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/schedule_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/sign_in_screen.dart';
import '../../presentation/screens/team_detail_screen.dart';
import '../../presentation/screens/team_search_screen.dart';

/// Normalizes only the registered Google OAuth completion URI. Returning null
/// leaves every ordinary or unknown location to GoRouter's normal handling.
String? googleCalendarOAuthRedirect(Uri uri) {
  if (uri.scheme == 'sportscalendar' &&
      uri.host == 'google-calendar' &&
      uri.path == '/oauth-complete') {
    return '/settings';
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) => googleCalendarOAuthRedirect(state.uri),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/search',
        builder: (context, state) => const TeamSearchScreen(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/team/:teamId',
        builder: (context, state) =>
            TeamDetailScreen(teamId: state.pathParameters['teamId']!),
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
