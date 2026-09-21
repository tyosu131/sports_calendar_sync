import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/widgets/public_policy_links.dart';

void main() {
  test('default public origin matches prepared Hosting content', () {
    final config = jsonDecode(File('hosting/site.json').readAsStringSync());
    expect(publicSiteUrl, config['publicUrl']);
    for (final origin in [
      'http://example.test',
      'https://user:secret@example.test',
      'https://example.test/path',
      'https://example.test?query=1',
    ]) {
      expect(
        () => publicPolicyUri('/privacy', origin: origin),
        throwsFormatException,
      );
    }
    expect(() => publicPolicyUri('//elsewhere.test'), throwsFormatException);
  });

  testWidgets('policy links work without Firebase or Google authorization', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicPolicyLinks(
            openUrl: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
    for (final label in ['アプリについて', 'プライバシーポリシー', '利用規約']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }
    expect(opened.map((uri) => uri.path), ['/', '/privacy', '/terms']);
    expect(opened.every((uri) => uri.scheme == 'https'), isTrue);
    expect(opened.map((uri) => uri.toString()), [
      'https://sports-calendar-sync.com/',
      'https://sports-calendar-sync.com/privacy',
      'https://sports-calendar-sync.com/terms',
    ]);
  });

  testWidgets('failed launch is sanitized and allows retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicPolicyLinks(
            openUrl: (_) async {
              calls++;
              throw StateError('private platform detail');
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pump();
    expect(find.textContaining('ページを開けませんでした'), findsOneWidget);
    expect(find.textContaining('private platform detail'), findsNothing);
    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pump();
    expect(calls, 2);
  });
}
