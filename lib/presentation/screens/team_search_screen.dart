import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/sports_registry.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/team_providers.dart';
import '../widgets/team_list_tile.dart';

/// Screen for searching and browsing teams by competition.
class TeamSearchScreen extends ConsumerStatefulWidget {
  const TeamSearchScreen({super.key});

  @override
  ConsumerState<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends ConsumerState<TeamSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  // Competitions sourced from SportsRegistry — single source of truth.
  static final _competitions = SportsRegistry.enabled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _competitions.length + 1, // +1 for "All" tab
      vsync: this,
    );
    // Keep teamSearchCompetitionKeyProvider in sync with the active tab.
    // Using an animation listener (fires on every frame during swipe as well
    // as on tap) ensures the provider is updated for both tap and swipe.
    _tabController.animation!.addListener(_onTabAnimationChanged);
  }

  void _onTabAnimationChanged() {
    // Round to the nearest integer tab index so the provider follows both
    // tap-based tab changes and swipe gestures without updating for every
    // fractional animation value.
    final index = _tabController.animation!.value.round();
    final key = index == 0 ? null : _competitions[index - 1].competitionKey;
    final notifier = ref.read(teamSearchCompetitionKeyProvider.notifier);
    if (notifier.state != key) {
      notifier.state = key;
    }
  }

  @override
  void dispose() {
    _tabController.animation!.removeListener(_onTabAnimationChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チームを探す'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'チーム名で検索...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(teamSearchQueryProvider.notifier).state = '';
                        },
                      ),
                  ],
                  onChanged: (value) {
                    ref.read(teamSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              // Competition tabs — driven by SportsRegistry.enabled
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'すべて'),
                  ..._competitions.map(
                    (s) => Tab(text: s.displayNameJa),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ref.watch(teamSearchQueryProvider).isNotEmpty
          ? _SearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                // "All" tab: no competition filter
                const _LeagueBrowser(competitionKey: null),
                // One tab per enabled competition
                ..._competitions.map(
                  (s) => _LeagueBrowser(competitionKey: s.competitionKey),
                ),
              ],
            ),
    );
  }
}

/// Shows search results from the query.
class _SearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(teamSearchResultsProvider);
    final followedIds = ref.watch(followedTeamIdsProvider);
    final user = ref.watch(currentUserProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          return const Center(child: Text('チームが見つかりませんでした'));
        }
        return ListView.builder(
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final isFollowing = followedIds.contains(team.id);
            return TeamListTile(
              team: team,
              isFollowing: isFollowing,
              onTap: () => context.push('/team/${team.id}'),
              onFollowToggle: () async {
                if (user == null) {
                  context.push('/signin');
                  return;
                }
                final repo = ref.read(userRepositoryProvider);
                if (isFollowing) {
                  await repo.unfollowTeam(
                    user.uid,
                    team.id,
                    competitionKey: team.competitionKey,
                  );
                } else {
                  await repo.followTeam(
                    user.uid,
                    team.id,
                    competitionKey: team.competitionKey,
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Browses leagues and their teams for a given competition.
class _LeagueBrowser extends ConsumerWidget {
  const _LeagueBrowser({this.competitionKey});

  /// null = show all competitions.
  final String? competitionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(leaguesByCompetitionProvider(competitionKey));
    final followedIds = ref.watch(followedTeamIdsProvider);
    final user = ref.watch(currentUserProvider);

    return leaguesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (leagues) {
        if (leagues.isEmpty) {
          return const Center(child: Text('リーグが見つかりませんでした'));
        }
        return ListView.builder(
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            final league = leagues[index];
            return ExpansionTile(
              leading: league.logoUrl != null
                  ? Image.network(league.logoUrl!, width: 32, height: 32)
                  : const Icon(Icons.sports),
              title: Text(league.nameJa),
              subtitle: Text(league.nameEn),
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final teamsAsync =
                        ref.watch(teamsByLeagueProvider(league.id));
                    return teamsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Text('エラー: $e'),
                      data: (teams) => Column(
                        children: teams.map((team) {
                          final isFollowing = followedIds.contains(team.id);
                          return TeamListTile(
                            team: team,
                            isFollowing: isFollowing,
                            onTap: () => context.push('/team/${team.id}'),
                            onFollowToggle: () async {
                              if (user == null) {
                                context.push('/signin');
                                return;
                              }
                              final repo = ref.read(userRepositoryProvider);
                              if (isFollowing) {
                                await repo.unfollowTeam(
                                  user.uid,
                                  team.id,
                                  competitionKey: team.competitionKey,
                                );
                              } else {
                                await repo.followTeam(
                                  user.uid,
                                  team.id,
                                  competitionKey: team.competitionKey,
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
