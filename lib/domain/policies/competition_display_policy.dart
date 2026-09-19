class CompetitionDisplayName {
  const CompetitionDisplayName({required this.label, required this.compact});

  final String label;
  final String compact;
}

/// Presentation catalog for competition identity already carried by Game.
abstract final class CompetitionDisplayPolicy {
  static const _names = <String, CompetitionDisplayName>{
    'football_j1': CompetitionDisplayName(label: 'J1リーグ', compact: 'J1'),
    'football_j_league_cup': CompetitionDisplayName(
      label: 'ルヴァンカップ',
      compact: 'ルヴァン',
    ),
    'football_emperor_cup': CompetitionDisplayName(
      label: '天皇杯',
      compact: '天皇杯',
    ),
    'football_premier': CompetitionDisplayName(
      label: 'Premier League',
      compact: 'PL',
    ),
    'football_champions_league': CompetitionDisplayName(
      label: 'Champions League',
      compact: 'UCL',
    ),
    'football_league_cup': CompetitionDisplayName(
      label: 'League Cup',
      compact: 'EFL Cup',
    ),
  };

  static CompetitionDisplayName? forKey(String? competitionKey) =>
      _names[competitionKey];
}
