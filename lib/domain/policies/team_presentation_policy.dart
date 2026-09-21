import '../models/game.dart';
import '../models/team.dart';
import 'club_presentation_data.dart';

/// Exact, presentation-only matching. Width, case, spaces and punctuation are
/// normalized; substrings, edit distance and provider IDs are never used.
String presentationNameKey(String value) {
  final width = String.fromCharCodes(
    value.runes.map((c) => c >= 0xff01 && c <= 0xff5e ? c - 0xfee0 : c),
  );
  return width.toLowerCase().replaceAll(RegExp(r'[\s.\-・&]'), '');
}

List<ClubPresentation> matchingClubPresentations(
  Iterable<String?> names, {
  List<ClubPresentation> entries = clubPresentationEntries,
  String? competitionKey,
}) {
  final keys = names
      .whereType<String>()
      .map(presentationNameKey)
      .where((key) => key.isNotEmpty)
      .toSet();
  return entries
      .where(
        (entry) =>
            entry.aliases.any(
              (alias) => keys.contains(presentationNameKey(alias)),
            ) ||
            (entry.competitionKeys.contains(competitionKey) &&
                entry.scopedAliases.any(
                  (alias) => keys.contains(presentationNameKey(alias)),
                )),
      )
      .toList();
}

ClubPresentation? clubPresentation(
  Iterable<String?> names, {
  List<ClubPresentation> entries = clubPresentationEntries,
  String? competitionKey,
}) {
  final matches = matchingClubPresentations(
    names,
    entries: entries,
    competitionKey: competitionKey,
  );
  return matches.length == 1 ? matches.single : null;
}

bool hasPresentationLogo(String? logo) =>
    logo != null && logo.trim().isNotEmpty;

/// Exact asset URL -> reviewed permission evidence. Provider availability and
/// existing master usage do not establish rights. No current asset is cleared.
const confirmedPublicLogoRights = <String, String>{};

String? publicTeamLogoUrl(
  String? candidate, {
  Map<String, String> rightsEvidence = confirmedPublicLogoRights,
}) {
  if (candidate == null ||
      (rightsEvidence[candidate]?.trim().isEmpty ?? true)) {
    return null;
  }
  final uri = Uri.tryParse(candidate);
  return uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? candidate
      : null;
}

/// Public UI boundary. Unverified Game/master/provider assets stay metadata.
String? teamPresentationLogo(Team team) =>
    publicTeamLogoUrl(teamPresentationLogoCandidate(team));

String? teamPresentationLogoCandidate(Team team) =>
    hasPresentationLogo(team.logoUrl)
    ? team.logoUrl
    : (team.competitionKey?.startsWith('football_') ?? false)
    ? clubPresentation([
        team.nameJa,
        team.nameEn,
      ], competitionKey: team.competitionKey)?.logoUrl
    : null;

/// A shared in-memory master index for a complete list of cards. It never
/// returns a canonical Team ID or changes a Game, follow, or membership.
class TeamPresentationLogoResolver {
  TeamPresentationLogoResolver(this.teams);
  final List<Team> teams;

  String? side(Game game, bool home) {
    final gameLogo = home ? game.homeTeamLogoUrl : game.awayTeamLogoUrl;
    if (hasPresentationLogo(gameLogo)) return gameLogo;
    final id = home ? game.homeTeamId : game.awayTeamId;
    final canonical = teams
        .where((team) => id != null && team.id == id)
        .toList();
    if (canonical.length == 1 &&
        hasPresentationLogo(canonical.single.logoUrl)) {
      return canonical.single.logoUrl;
    }
    if (!(game.competitionKey?.startsWith('football_') ?? false)) return null;
    final names = home
        ? [game.homeTeamNameEn, game.homeTeamProviderName, game.homeTeamNameJa]
        : [game.awayTeamNameEn, game.awayTeamProviderName, game.awayTeamNameJa];
    final candidates = matchingClubPresentations(
      names,
      competitionKey: game.competitionKey,
    );
    if (candidates.length > 1) return null;
    final entry = candidates.isEmpty ? null : candidates.single;
    final keys = <String>{
      ...names.whereType<String>().map(presentationNameKey),
      if (entry != null) ...entry.aliases.map(presentationNameKey),
    }..remove('');
    final matches = teams
        .where(
          (team) =>
              (team.competitionKey?.startsWith('football_') ?? false) &&
              [
                team.nameJa,
                team.nameEn,
              ].map(presentationNameKey).any(keys.contains),
        )
        .toList();
    if (matches.length > 1) return null;
    if (matches.length == 1 && hasPresentationLogo(matches.single.logoUrl)) {
      return matches.single.logoUrl;
    }
    return entry?.logoUrl;
  }
}
