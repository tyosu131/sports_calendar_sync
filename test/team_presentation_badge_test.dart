import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/widgets/team_presentation_badge.dart';

void main() {
  testWidgets('neutral badge uses the first rune and never a shield', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            TeamPresentationBadge(displayName: '川崎フロンターレ'),
            TeamPresentationBadge(displayName: 'Arsenal'),
          ],
        ),
      ),
    );

    expect(find.text('川'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
  });

  testWidgets('an image load failure uses the same neutral initial', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TeamPresentationBadge(
          displayName: 'ロアッソ熊本',
          logoUrl: 'not-a-valid-url',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ロ'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
  });

  testWidgets('neutral fallback is a generic mark labeled with the full name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TeamPresentationBadge(
          displayName: '川崎フロンターレ',
          fallback: TeamBadgeFallback.neutralMark,
        ),
      ),
    );

    expect(find.byKey(const Key('neutral-team-mark')), findsOneWidget);
    expect(find.text('川'), findsNothing);
    expect(find.text('川崎'), findsNothing);
    expect(find.text('川崎F'), findsNothing);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    expect(
      tester.getSemantics(find.byType(TeamPresentationBadge)).label,
      '川崎フロンターレ',
    );
  });

  testWidgets('a failed logo on the neutral fallback stays a generic mark', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TeamPresentationBadge(
          displayName: 'ロアッソ熊本',
          logoUrl: 'not-a-valid-url',
          fallback: TeamBadgeFallback.neutralMark,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('neutral-team-mark')), findsOneWidget);
    expect(find.text('ロ'), findsNothing);
    expect(
      tester.getSemantics(find.byType(TeamPresentationBadge)).label,
      'ロアッソ熊本',
    );
  });
}
