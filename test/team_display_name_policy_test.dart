import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/utils/auth_failure_message.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/team_display_name_policy.dart';

Game game({
  required String competition,
  required String homeJa,
  required String awayJa,
  String? homeEn,
  String? awayEn,
  String? homeProvider,
  String? awayProvider,
  String? homeTeamId,
  String? awayTeamId,
}) => Game(
      id: 'game',
      leagueId: 'league',
      competitionKey: competition,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeTeamNameJa: homeJa,
      awayTeamNameJa: awayJa,
      homeTeamNameEn: homeEn,
      awayTeamNameEn: awayEn,
      homeTeamProviderName: homeProvider,
      awayTeamProviderName: awayProvider,
      startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 9, 19, 9)),
      startTimeJst: '2026-09-19 18:00',
      timezone: 'UTC',
      status: GameStatus.scheduled,
    );

void main() {
  test('all six V1 competition defaults are explicit', () {
    for (final key in [
      'football_j1',
      'football_j_league_cup',
      'football_emperor_cup',
    ]) {
      expect(teamDisplayNames.languageFor(key), DisplayLanguage.japanese);
    }
    for (final key in [
      'football_premier',
      'football_champions_league',
      'football_league_cup',
    ]) {
      expect(teamDisplayNames.languageFor(key), DisplayLanguage.english);
    }
  });

  test('domestic names use confirmed Japanese evidence', () {
    final value = game(
      competition: 'football_j1',
      homeJa: 'Kawasaki Frontale',
      awayJa: 'Kashima Antlers',
      homeEn: 'Kawasaki Frontale',
      awayEn: 'Kashima Antlers',
    );
    expect(teamDisplayNames.homeName(value), '川崎フロンターレ');
    expect(teamDisplayNames.awayName(value), '鹿島アントラーズ');
    expect(value.awayTeamId, isNull);
  });

  test('domestic cups localize J2 and J3 evidence without identity', () {
    final value = game(
      competition: 'football_emperor_cup',
      homeJa: 'Vegalta Sendai',
      awayJa: 'FC Gifu',
      homeEn: 'Vegalta Sendai',
      awayEn: 'FC Gifu',
    );
    expect(teamDisplayNames.homeName(value), 'ベガルタ仙台');
    expect(teamDisplayNames.awayName(value), 'ＦＣ岐阜');
    expect(value.homeTeamId, isNull);
    expect(value.awayTeamId, isNull);
  });

  test('safe normalization handles width punctuation whitespace and case', () {
    final value = game(
      competition: 'football_j_league_cup',
      homeJa: 'provider value',
      awayJa: 'provider value',
      homeProvider: '  kyoto  sanga f．c． ',
      awayProvider: 'f c   gifu',
    );
    expect(teamDisplayNames.homeName(value), '京都サンガF.C.');
    expect(teamDisplayNames.awayName(value), 'ＦＣ岐阜');
  });

  test('European names use English', () {
    final value = game(
      competition: 'football_premier',
      homeJa: 'ブライトン',
      awayJa: 'アーセナル',
      homeEn: 'Brighton & Hove Albion',
      awayEn: 'Arsenal',
    );
    expect(teamDisplayNames.homeName(value), 'Brighton & Hove Albion');
    expect(teamDisplayNames.awayName(value), 'Arsenal');
  });

  test('canonical team id wins over provider display text', () {
    final value = game(
      competition: 'football_premier',
      homeTeamId: 'arsenal',
      homeJa: 'Provider Arsenal',
      homeEn: 'Provider Arsenal',
      homeProvider: 'Provider Arsenal',
      awayJa: 'Leeds United',
      awayProvider: 'Leeds United',
    );
    expect(teamDisplayNames.homeName(value), 'Arsenal');
    expect(teamDisplayNames.awayName(value), 'Leeds United');
  });

  test('unknown domestic translation safely uses provider name', () {
    final value = game(
      competition: 'football_j1',
      homeJa: 'Unknown Provider FC',
      awayJa: '川崎フロンターレ',
      homeEn: 'Unknown Provider FC',
    );
    expect(teamDisplayNames.homeName(value), 'Unknown Provider FC');
    expect(value.homeTeamId, isNull);
  });

  test('team master primary label follows default discovery competition', () {
    const kawasaki = Team(id: 'kawasaki_frontale', nameEn: 'Kawasaki Frontale',
      nameJa: '川崎フロンターレ', leagueId: 'j1', competitionKey: 'football_j1');
    const arsenal = Team(id: 'arsenal', nameEn: 'Arsenal', nameJa: 'アーセナル',
      leagueId: 'premier', competitionKey: 'football_premier');
    expect(teamDisplayNames.teamName(kawasaki), '川崎フロンターレ');
    expect(teamDisplayNames.teamName(arsenal), 'Arsenal');
  });

  test('auth failure copy does not expose platform exception details', () {
    expect(authenticationFailureMessage('Apple'), contains('Apple'));
    expect(authenticationFailureMessage('Apple'), isNot(contains('1000')));
  });
}
