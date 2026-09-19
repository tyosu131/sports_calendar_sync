enum CompetitionDisplayLanguage { japanese, english }

class CompetitionDisplayName {
  const CompetitionDisplayName({
    required this.nameJa,
    required this.nameEn,
    required this.compact,
    required this.defaultLanguage,
  });

  final String nameJa;
  final String nameEn;
  final String compact;
  final CompetitionDisplayLanguage defaultLanguage;

  String get label => defaultLanguage == CompetitionDisplayLanguage.japanese
      ? nameJa
      : nameEn;
}

/// Presentation metadata for the current V1 competition scope only.
abstract final class CompetitionDisplayPolicy {
  static const _names = <String, CompetitionDisplayName>{
    'football_j1': CompetitionDisplayName(
      nameJa: 'J1リーグ',
      nameEn: 'J1 League',
      compact: 'J1',
      defaultLanguage: CompetitionDisplayLanguage.japanese,
    ),
    'football_j_league_cup': CompetitionDisplayName(
      nameJa: 'ルヴァンカップ',
      nameEn: 'J.League Cup',
      compact: 'ルヴァン',
      defaultLanguage: CompetitionDisplayLanguage.japanese,
    ),
    'football_emperor_cup': CompetitionDisplayName(
      nameJa: '天皇杯',
      nameEn: "Emperor's Cup",
      compact: '天皇杯',
      defaultLanguage: CompetitionDisplayLanguage.japanese,
    ),
    'football_premier': CompetitionDisplayName(
      nameJa: 'プレミアリーグ',
      nameEn: 'Premier League',
      compact: 'PL',
      defaultLanguage: CompetitionDisplayLanguage.english,
    ),
    'football_champions_league': CompetitionDisplayName(
      nameJa: 'UEFAチャンピオンズリーグ',
      nameEn: 'Champions League',
      compact: 'UCL',
      defaultLanguage: CompetitionDisplayLanguage.english,
    ),
    'football_league_cup': CompetitionDisplayName(
      nameJa: 'リーグカップ',
      nameEn: 'League Cup',
      compact: 'EFL Cup',
      defaultLanguage: CompetitionDisplayLanguage.english,
    ),
  };

  static CompetitionDisplayName? forKey(String? competitionKey) =>
      _names[competitionKey];
}
