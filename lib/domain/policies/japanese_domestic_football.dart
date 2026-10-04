/// Whether [competitionKey] is a Japanese domestic football competition.
///
/// J.League competitions share the `football_j` prefix: J1, J2, J3, the
/// J.League Cup, and domestic specials such as `football_j2_j3_special`.
/// A future J.League key that keeps that prefix is domestic without another
/// allowlist edit. The Emperor's Cup does not use the prefix and is named
/// explicitly. Premier League, Champions League, and the English League Cup
/// (`football_league_cup`) stay outside. A missing key is not a domestic
/// context. This does not classify baseball, basketball, or other sports.
bool isJapaneseDomesticFootballCompetition(String? competitionKey) {
  final key = competitionKey?.trim();
  if (key == null || key.isEmpty) return false;
  return key.startsWith('football_j') || key == 'football_emperor_cup';
}
