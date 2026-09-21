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
}
