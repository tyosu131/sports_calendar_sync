import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/widgets/ics_share_sheet.dart';

void main() {
  testWidgets('offers Apple and generic URL actions without a Google ICS action',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IcsShareSheet(icsUrl: 'https://example.com/calendar.ics'),
        ),
      ),
    );

    expect(find.text('Appleカレンダーで開く'), findsOneWidget);
    expect(find.byTooltip('URLをコピー'), findsOneWidget);
    expect(find.text('URLをシェア'), findsOneWidget);
    expect(find.textContaining('Googleカレンダーに手動登録'), findsNothing);
  });

  test('active Flutter code has no legacy Google Calendar subscription route',
      () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('www.google.com/calendar/render?cid=')),
        reason: file.path,
      );
    }
  });
}
