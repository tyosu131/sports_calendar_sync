import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/utils/app_router.dart';

void main() {
  test('normalizes only the exact Google OAuth completion deep link', () {
    expect(
      googleCalendarOAuthRedirect(
        Uri.parse('sportscalendar://google-calendar/oauth-complete'),
      ),
      '/settings',
    );
    expect(googleCalendarOAuthRedirect(Uri.parse('/settings')), isNull);
    expect(
      googleCalendarOAuthRedirect(
        Uri.parse('sportscalendar://unexpected/path'),
      ),
      isNull,
    );
  });

  test('registers a single league team route and not one route per league', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);

    final match = router.configuration.findMatch(
      Uri.parse('/league/football_j1'),
    );
    expect(match.isError, isFalse);
    expect(match.uri.path, '/league/football_j1');
    expect(
      router.configuration.findMatch(Uri.parse('/league/baseball_npb')).isError,
      isFalse,
    );
    expect(
      router.configuration.findMatch(Uri.parse('/leagues/football_j1')).isError,
      isTrue,
    );
  });
}
