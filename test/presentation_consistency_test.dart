import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/team_repository.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/policies/game_presentation_policy.dart';
import 'package:sports_calendar_sync/domain/policies/team_initial.dart';

void main() {
  test('team initial is rune-safe and normalizes only its full-width initial', () {
    expect(teamInitial('川崎フロンターレ'), '川');
    expect(teamInitial('Arsenal'), 'A');
    expect(teamInitial('ＦＣ東京'), 'F');
    expect(teamInitial('Ｖ・ファーレン長崎'), 'V');
    expect(teamInitial(''), '?');
  });

  test('all statuses share one semantic label and role policy', () {
    expect(GameStatusPresentation.forStatus(GameStatus.scheduled), isNull);
    expect(GameStatusPresentation.forStatus(GameStatus.live)?.label, 'LIVE');
    expect(GameStatusPresentation.forStatus(GameStatus.finished)?.label, '終了');
    expect(GameStatusPresentation.forStatus(GameStatus.postponed)?.label, '延期');
    expect(GameStatusPresentation.forStatus(GameStatus.cancelled)?.label, '中止');
    expect(GameStatusPresentation.forStatus(GameStatus.live)?.colorRole, GameStatusColorRole.live);
    expect(GameStatusPresentation.forStatus(GameStatus.cancelled)?.colorRole, GameStatusColorRole.cancelled);
  });

  test('score formats zero and non-zero pairs but rejects partial scores', () {
    expect(formatScore(0, 0), '0 - 0');
    expect(formatScore(3, 3), '3 - 3');
    expect(formatScore(0, 0, format: ScoreFormat.compact), '0-0');
    expect(formatScore(3, 3, format: ScoreFormat.compact), '3-3');
    expect(formatScore(3, null), isNull);
    expect(formatScore(null, 3), isNull);
  });

  test('venue hides blank values and preserves real value', () {
    expect(visibleVenue(null), isNull);
    expect(visibleVenue(''), isNull);
    expect(visibleVenue('   '), isNull);
    expect(visibleVenue('Ajinomoto Stadium'), 'Ajinomoto Stadium');
  });

  test('search width variants are bidirectional and bounded', () {
    expect(teamSearchWidthVariants('FC東京'), ['FC東京', 'ＦＣ東京']);
    expect(teamSearchWidthVariants('ＦＣ東京'), ['ＦＣ東京', 'FC東京']);
    expect(teamSearchWidthVariants('栃木SC'), ['栃木SC', '栃木ＳＣ']);
    expect(teamSearchWidthVariants('ＲＢ大宮'), ['ＲＢ大宮', 'RB大宮']);
    expect(teamSearchWidthVariants('FC東京').length, lessThanOrEqualTo(2));
    expect(maxTeamSearchWidthVariants, 2);
    // Two prefix and up to six keyword variants, doubled only for the
    // competitionKey/sportKey compatibility paths.
    expect(maxTeamSearchRepositoryReads, 16);
  });
}
