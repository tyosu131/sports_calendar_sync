import '../../core/config/sports_registry.dart';
import '../models/game.dart';
import '../models/team.dart';

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
