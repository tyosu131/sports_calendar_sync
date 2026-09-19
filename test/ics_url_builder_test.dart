import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/utils/ics_url_builder.dart';

void main() {
  test('personalized URL contains only the opaque token credential', () {
    final token = 'a' * 43;
    final url = IcsUrlBuilder.buildForToken(token);
    final uri = Uri.parse(url);

    expect(uri.queryParameters['token'], token);
    expect(uri.queryParameters.containsKey('uid'), isFalse);
    expect(uri.queryParameters.containsKey('teamId'), isFalse);
    expect(uri.queryParameters.length, 1);
  });

  test('user-wide URL is stable for the same token', () {
    final token = 'b' * 43;
    expect(token.length, 43);
    expect(IcsUrlBuilder.buildForToken(token), IcsUrlBuilder.buildForToken(token));
  });
}
