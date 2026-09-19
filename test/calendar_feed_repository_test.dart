import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/calendar_feed_repository.dart';

void main() {
  const token = 'abcdefghijklmnopqrstuvwxyzABCDEFGH012345678';

  test('ensure parses a valid token from its authenticated callable', () async {
    String? called;
    final repository = CalendarFeedRepository(call: (name) async {
      called = name;
      return {'token': token};
    });

    expect(await repository.ensureCalendarFeed(), token);
    expect(called, 'ensureCalendarFeed');
  });

  test('rotate invokes the rotation callable and parses its token', () async {
    final repository = CalendarFeedRepository(call: (name) async {
      expect(name, 'rotateCalendarFeed');
      return {'token': token};
    });

    expect(await repository.rotateCalendarFeed(), token);
  });

  for (final result in <Object?>[
    null,
    {},
    {'token': 'short'},
    {'token': '${'a' * 42}+'},
    {'token': 123},
  ]) {
    test('malformed callable result is rejected: $result', () async {
      final repository = CalendarFeedRepository(call: (_) async => result);
      await expectLater(
        repository.ensureCalendarFeed(),
        throwsA(isA<InvalidCalendarFeedResponse>()),
      );
    });
  }
}
