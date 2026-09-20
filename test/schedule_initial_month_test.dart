import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/screens/schedule_screen.dart';

void main() {
  final augustToNovember = [
    DateTime(2026, 8, 2),
    DateTime(2026, 11, 28),
  ];

  test('current JST month inside range is used', () {
    expect(
      resolveInitialVisibleMonth(
        augustToNovember,
        DateTime.utc(2026, 9, 20),
      ),
      DateTime(2026, 9),
    );
  });

  test('current JST month before range clamps to minimum month', () {
    expect(
      resolveInitialVisibleMonth(augustToNovember, DateTime.utc(2026, 7, 20)),
      DateTime(2026, 8),
    );
  });

  test('current JST month after range clamps to maximum month', () {
    expect(
      resolveInitialVisibleMonth(augustToNovember, DateTime.utc(2026, 12, 20)),
      DateTime(2026, 11),
    );
  });

  test('UTC clock is converted to JST before choosing the month', () {
    expect(
      resolveInitialVisibleMonth(
        [DateTime(2026, 8), DateTime(2026, 9)],
        DateTime.utc(2026, 8, 31, 15),
      ),
      DateTime(2026, 9),
    );
  });
}
