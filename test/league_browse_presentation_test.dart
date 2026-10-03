import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/league_browse_presentation.dart';
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

  test('card label is the canonical name, not a search alias', () {
    const forbidden = ['川崎', '横浜', '町田', '鹿島', 'Giants'];

    void expectFull(String actual, String full) {
      expect(actual, full);
      expect(forbidden, isNot(contains(actual)));
    }

    expectFull(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'kashima_antlers',
          nameEn: 'Kashima Antlers',
          nameJa: '鹿島アントラーズ',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      '鹿島アントラーズ',
    );
    expectFull(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'urawa_reds',
          nameEn: 'Urawa Reds',
          nameJa: '浦和レッズ',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      '浦和レッズ',
    );
    expectFull(
      leagueTeamCardLabelForTeam(
        const Team(
          id: 'kawasaki_frontale',
          nameEn: 'Kawasaki Frontale',
          nameJa: '川崎フロンターレ',
          leagueId: 'league',
          competitionKey: 'football_j1',
        ),
      ),
      '川崎フロンターレ',
    );
    expectFull(
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
    expectFull(
      leagueTeamCardLabelForName('Kashima Antlers'),
      'Kashima Antlers',
    );
    expectFull(
      leagueTeamCardLabelForName('Tottenham Hotspur'),
      'Tottenham Hotspur',
    );
    expectFull(leagueTeamCardLabelForName('Tochigi SC'), 'Tochigi SC');
    expectFull(
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
    expectFull(
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
    expectFull(
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
    expectFull(
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
    expectFull(leagueTeamCardLabel('Yomiuri Giants'), 'Yomiuri Giants');
    expectFull(leagueTeamCardLabel('読売ジャイアンツ'), '読売ジャイアンツ');
    expectFull(leagueTeamCardLabel('とても長い架空のクラブ名テスト'), 'とても長い架空のクラブ名テスト');
  });
}
