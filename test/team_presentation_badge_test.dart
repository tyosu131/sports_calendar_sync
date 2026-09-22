import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/widgets/team_presentation_badge.dart';

void main() {
  testWidgets('neutral badge uses the first rune and never a shield',
      (tester) async {
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

  testWidgets('an image load failure uses the same neutral initial',
      (tester) async {
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
}
