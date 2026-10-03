import '../../core/config/sports_registry.dart';
import '../models/game.dart';
import '../models/sport_definition.dart';
import '../models/team.dart';
import 'competition_display_policy.dart';

/// Identifiers for the Home sport navigation.
///
/// These are sport groupings already present in [SportsRegistry], not leagues.
abstract final class HomeSportTabIds {
  static const favorites = 'favorites';
  static const baseball = 'baseball';
  static const football = 'football';
  static const other = 'other';
}

/// One Home tab. [sportCategories] null means お気に入り (every follow).
class HomeSportTab {
  const HomeSportTab({
    required this.id,
    required this.label,
    this.sportCategories,
  });

  final String id;
  final String label;

  /// Enabled [SportDefinition.sportCategory] values included by this tab.
  ///
  /// Null includes every followed team and game. A non-null set excludes
  /// targets whose competition key does not resolve to one of these
  /// categories; those targets stay on お気に入り.
  final Set<String>? sportCategories;

  bool get showsAllSports => sportCategories == null;

  bool acceptsCategory(String? category) {
    final categories = sportCategories;
    if (categories == null) return true;
    return category != null && categories.contains(category);
  }
}

const _baseballCategory = 'baseball';
const _footballCategory = 'football';

/// Home opens on お気に入り, then 野球, サッカー, and その他スポーツ.
///
/// A primary tab is omitted when that category is not enabled. Every other
/// enabled category is grouped into その他スポーツ. League names are never tabs.
List<HomeSportTab> homeSportTabs({List<String>? enabledCategories}) {
  final present = (enabledCategories ?? SportsRegistry.enabledCategories)
      .toSet();
  final tabs = <HomeSportTab>[
    const HomeSportTab(id: HomeSportTabIds.favorites, label: 'お気に入り'),
  ];
  if (present.contains(_baseballCategory)) {
    tabs.add(
      const HomeSportTab(
        id: HomeSportTabIds.baseball,
        label: '野球',
        sportCategories: {_baseballCategory},
      ),
    );
  }
  if (present.contains(_footballCategory)) {
    tabs.add(
      const HomeSportTab(
        id: HomeSportTabIds.football,
        label: 'サッカー',
        sportCategories: {_footballCategory},
      ),
    );
  }
  final other = present.difference({_baseballCategory, _footballCategory});
  if (other.isNotEmpty) {
    tabs.add(
      HomeSportTab(
        id: HomeSportTabIds.other,
        label: 'その他スポーツ',
        sportCategories: Set.unmodifiable(other),
      ),
    );
  }
  return List.unmodifiable(tabs);
}

/// Index of お気に入り. This is the Home default.
int defaultHomeSportTabIndex(List<HomeSportTab> tabs) {
  final index = tabs.indexWhere((tab) => tab.id == HomeSportTabIds.favorites);
  return index < 0 ? 0 : index;
}

/// Category for a competition key already used by teams and games.
///
/// Registry entries win. Keys that are not registered (cups, J2/J3) still
/// match the enabled competition-key prefix, so `football_emperor_cup` stays
/// football. Unknown keys return null and are shown only on お気に入り.
String? sportCategoryForCompetitionKey(String? competitionKey) {
  final key = competitionKey?.trim();
  if (key == null || key.isEmpty) return null;

  final defined = SportsRegistry.findByKey(key);
  if (defined != null) return defined.sportCategory;

  String? category;
  var prefixLength = 0;
  for (final definition in SportsRegistry.enabled) {
    final prefix = definition.competitionKey.split('_').first;
    final matches = key == prefix || key.startsWith('${prefix}_');
    if (matches && prefix.length > prefixLength) {
      category = definition.sportCategory;
      prefixLength = prefix.length;
    }
  }
  return category;
}

List<Team> teamsForHomeSportTab(List<Team> teams, HomeSportTab tab) {
  if (tab.showsAllSports) return teams;
  return [
    for (final team in teams)
      if (tab.acceptsCategory(
        sportCategoryForCompetitionKey(team.competitionKey),
      ))
        team,
  ];
}

List<Game> gamesForHomeSportTab(List<Game> games, HomeSportTab tab) {
  if (tab.showsAllSports) return games;
  return [
    for (final game in games)
      if (tab.acceptsCategory(
        sportCategoryForCompetitionKey(game.competitionKey),
      ))
        game,
  ];
}

/// Identifiers for the two destinations inside a sport tab.
///
/// お気に入り has neither. League names are never destinations.
abstract final class SportSubNavIds {
  static const home = 'home';
  static const leagues = 'leagues';
}

/// One fixed bottom destination. [label] is always visible with the icon.
class SportSubNavDestination {
  const SportSubNavDestination({required this.id, required this.label});

  final String id;
  final String label;
}

/// Exactly ホーム and リーグ. Do not append competitions here.
const sportSubNavDestinations = <SportSubNavDestination>[
  SportSubNavDestination(id: SportSubNavIds.home, label: 'ホーム'),
  SportSubNavDestination(id: SportSubNavIds.leagues, label: 'リーグ'),
];

/// Favorites is cross-sport, so it does not show ホーム | リーグ.
bool homeTabShowsSportSubNav(HomeSportTab tab) => !tab.showsAllSports;

int sportSubNavIndexFor(String id) {
  final index = sportSubNavDestinations.indexWhere((item) => item.id == id);
  return index < 0 ? 0 : index;
}

/// Enabled competitions for a set of [SportDefinition.sportCategory] values.
///
/// Search and Follow still list [SportsRegistry.enabled] as flat tabs. They
/// can group that list with this function later without adding leagues to the
/// bottom navigation.
List<SportDefinition> competitionsForSportCategories(Set<String> categories) {
  if (categories.isEmpty) return const [];
  return List<SportDefinition>.unmodifiable([
    for (final competition in SportsRegistry.enabled)
      if (categories.contains(competition.sportCategory)) competition,
  ]);
}

/// Registry competitions that belong to [tab]. Favorites returns an empty list.
List<SportDefinition> competitionsForHomeSportTab(HomeSportTab tab) {
  final categories = tab.sportCategories;
  if (categories == null) return const [];
  return competitionsForSportCategories(categories);
}

/// Sport tabs paired with their registry competitions, favorites omitted.
///
/// This is the sport → league model Search can reuse. It is not a list of
/// bottom-nav destinations.
class SportLeagueGroup {
  const SportLeagueGroup({required this.tab, required this.competitions});

  final HomeSportTab tab;
  final List<SportDefinition> competitions;
}

List<SportLeagueGroup> sportLeagueGroups({List<HomeSportTab>? tabs}) {
  return List<SportLeagueGroup>.unmodifiable([
    for (final tab in tabs ?? homeSportTabs())
      if (homeTabShowsSportSubNav(tab))
        SportLeagueGroup(
          tab: tab,
          competitions: competitionsForHomeSportTab(tab),
        ),
  ]);
}

/// Client-side filter over registry display names. No network request.
List<SportDefinition> filterSportCompetitions(
  List<SportDefinition> competitions,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return List<SportDefinition>.unmodifiable(competitions);
  }
  return List<SportDefinition>.unmodifiable([
    for (final competition in competitions)
      if (_competitionMatches(competition, normalized)) competition,
  ]);
}

bool _competitionMatches(SportDefinition competition, String normalizedQuery) {
  final display = CompetitionDisplayPolicy.forKey(competition.competitionKey);
  final haystack = [
    competition.displayNameJa,
    competition.displayNameEn,
    if (display != null) ...[
      display.compact,
      display.nameJa,
      display.nameEn,
      display.label,
    ],
  ].join('\n').toLowerCase();
  return haystack.contains(normalizedQuery);
}

/// Short neutral label for a competition row. Not a flag or crest.
String competitionBadgeLabel(SportDefinition competition) {
  final compact = CompetitionDisplayPolicy.forKey(
    competition.competitionKey,
  )?.compact.trim();
  if (compact != null && compact.isNotEmpty) return compact;
  final name = competition.displayNameJa.trim();
  if (name.runes.length <= 4) return name;
  return String.fromCharCodes(name.runes.take(2));
}
