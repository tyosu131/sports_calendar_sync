import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/league_browse_presentation.dart';
import 'package:sports_calendar_sync/domain/policies/team_display_name_policy.dart';
import 'package:sports_calendar_sync/presentation/theme/league_browse_accents.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  test('accent is stable, dark, and chosen from the fixed palette', () {
    expect(leagueBrowseAccents, hasLength(8));
    expect(leagueBrowseAccents.toSet(), hasLength(8));
    for (final color in leagueBrowseAccents) {
      expect(color.computeLuminance(), lessThan(0.25));
      expect(color, isNot(equals(Colors.grey)));
    }
    expect(
      leagueBrowseAccent('kashima_antlers'),
      leagueBrowseAccent('kashima_antlers'),
    );
    expect(
      leagueBrowseAccents,
      contains(leagueBrowseAccent('kashima_antlers')),
    );
    expect(leagueBrowseAccents, contains(leagueBrowseAccent('football_j1')));
  });

  test('card label uses a short catalog prefix, else a trailing token', () {
    expect(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'kashima_antlers',
          nameEn: 'Kashima Antlers',
          nameJa: '鹿島アントラーズ',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      '鹿島',
    );
    expect(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'urawa_reds',
          nameEn: 'Urawa Reds',
          nameJa: '浦和レッズ',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      '浦和',
    );
    expect(
      leagueTeamCardLabel(
        displayName: 'Yomiuri Giants',
        language: DisplayLanguage.english,
      ),
      'Giants',
    );
    expect(
      leagueTeamCardLabel(
        displayName: '読売ジャイアンツ',
        language: DisplayLanguage.japanese,
      ),
      '読売ジャイアンツ',
    );
  });
}
