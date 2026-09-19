import '../models/game.dart';
import '../models/team.dart';

/// Optional override point for a future explicit user language preference.
enum DisplayLanguage { japanese, english }

/// The single app-side policy for choosing team names.
///
/// A name lookup only affects presentation. It never assigns or implies a
/// canonical Team id.
class TeamDisplayNamePolicy {
  const TeamDisplayNamePolicy({this.languageOverride});

  final DisplayLanguage? languageOverride;

  static const _japaneseCompetitions = {
    'football_j1',
    'football_j_league_cup',
    'football_emperor_cup',
  };

  static const _confirmedJapaneseByEnglish = <String, String>{
    'Kashima': '鹿島アントラーズ',
    'Kashima Antlers': '鹿島アントラーズ',
    'Mito Hollyhock': '水戸ホーリーホック',
    'Urawa Reds': '浦和レッズ',
    'JEF United Chiba': 'ジェフユナイテッド千葉',
    'JEF Chiba': 'ジェフユナイテッド千葉',
    'Kashiwa Reysol': '柏レイソル',
    'FC Tokyo': 'ＦＣ東京',
    'Tokyo Verdy': '東京ヴェルディ',
    'FC Machida Zelvia': 'ＦＣ町田ゼルビア',
    'Machida Zelvia': 'ＦＣ町田ゼルビア',
    'Kawasaki Frontale': '川崎フロンターレ',
    'Yokohama F・Marinos': '横浜Ｆ・マリノス',
    'Yokohama F. Marinos': '横浜Ｆ・マリノス',
    'Shimizu S-Pulse': '清水エスパルス',
    'Nagoya Grampus': '名古屋グランパス',
    'Kyoto Sanga F.C.': '京都サンガF.C.',
    'Kyoto Sanga': '京都サンガF.C.',
    'Gamba Osaka': 'ガンバ大阪',
    'Cerezo Osaka': 'セレッソ大阪',
    'Vissel Kobe': 'ヴィッセル神戸',
    'Fagiano Okayama': 'ファジアーノ岡山',
    'Sanfrecce Hiroshima': 'サンフレッチェ広島',
    'Avispa Fukuoka': 'アビスパ福岡',
    'V-Varen Nagasaki': 'Ｖ・ファーレン長崎',
    'V. Varen Nagasaki': 'Ｖ・ファーレン長崎',
  };

  DisplayLanguage languageFor(String? competitionKey) => languageOverride ??
      (_japaneseCompetitions.contains(competitionKey)
          ? DisplayLanguage.japanese
          : DisplayLanguage.english);

  String teamName(Team team) => _select(
        competitionKey: team.competitionKey,
        japanese: team.nameJa,
        english: team.nameEn,
      );

  String homeName(Game game) => _select(
        competitionKey: game.competitionKey,
        japanese: game.homeTeamNameJa,
        english: game.homeTeamNameEn,
        provider: game.homeTeamProviderName,
      );

  String awayName(Game game) => _select(
        competitionKey: game.competitionKey,
        japanese: game.awayTeamNameJa,
        english: game.awayTeamNameEn,
        provider: game.awayTeamProviderName,
      );

  String _select({
    required String? competitionKey,
    required String japanese,
    required String? english,
    String? provider,
  }) {
    final ja = japanese.trim();
    final en = english?.trim() ?? '';
    final raw = provider?.trim() ?? '';
    if (languageFor(competitionKey) == DisplayLanguage.english) {
      return en.isNotEmpty ? en : raw.isNotEmpty ? raw : ja;
    }

    // GOAL legacy documents may contain the provider's English value in the
    // *NameJa field. Only use repository-confirmed master evidence to localize.
    final confirmed = _confirmedJapaneseByEnglish[en] ??
        _confirmedJapaneseByEnglish[raw] ?? _confirmedJapaneseByEnglish[ja];
    if (confirmed != null) return confirmed;
    if (_containsJapanese(ja)) return ja;
    return raw.isNotEmpty ? raw : en.isNotEmpty ? en : ja;
  }

  bool _containsJapanese(String value) =>
      RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(value);
}

const teamDisplayNames = TeamDisplayNamePolicy();
