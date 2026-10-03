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

  test('card label uses a catalog prefix, else the full name', () {
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
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'kawasaki_frontale',
          nameEn: 'Kawasaki Frontale',
          nameJa: '川崎フロンターレ',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      '川崎',
    );
    expect(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'kawasaki_frontale',
          nameEn: 'Kawasaki Frontale',
          nameJa: '川崎フロンターレ',
          leagueId: 'league',
          competitionKey: 'football_premier',
        ),
      ),
      'Kawasaki Frontale',
    );
    expect(
      leagueTeamCardLabelForName(
        'Kashima Antlers',
        competitionKey: 'football_premier',
      ),
      'Kashima',
    );
    expect(
      leagueTeamCardLabelForName(
        'Tottenham Hotspur',
        competitionKey: 'football_premier',
      ),
      'Tottenham',
    );
    expect(
      leagueTeamCardLabelForName('Tochigi SC', competitionKey: 'football_j2'),
      'Tochigi SC',
    );
    expect(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'fc_machida_zelvia',
          nameEn: 'FC Machida Zelvia',
          nameJa: 'ＦＣ町田ゼルビア',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      'ＦＣ町田ゼルビア',
    );
    expect(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'yokohama_f_marinos',
          nameEn: 'Yokohama F. Marinos',
          nameJa: '横浜Ｆ・マリノス',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      '横浜Ｆ・マリノス',
    );
    expect(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'tochigi_sc',
          nameEn: 'Tochigi SC',
          nameJa: '栃木ＳＣ',
          leagueId: 'league',
          competitionKey: 'football_j2',
        ),
      ),
      '栃木ＳＣ',
    );
    expect(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'yomiuri_giants',
          nameEn: 'Yomiuri Giants',
          nameJa: '読売ジャイアンツ',
          leagueId: 'league',
          competitionKey: 'baseball_npb',
        ),
      ),
      'Yomiuri Giants',
    );
    expect(
      leagueTeamCardLabel(
        displayName: 'Yomiuri Giants',
        language: DisplayLanguage.english,
      ),
      'Yomiuri Giants',
    );
    expect(
      leagueTeamCardLabel(
        displayName: '読売ジャイアンツ',
        language: DisplayLanguage.japanese,
      ),
      '読売ジャイアンツ',
    );
    expect(
      leagueTeamCardLabel(
        displayName: 'とても長い架空のクラブ名テスト',
        language: DisplayLanguage.japanese,
      ),
      'とても長い架空のクラブ名テスト',
    );
  });
}
