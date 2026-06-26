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
      length: _competitions.length + 1, // Followed + competitions
      vsync: this,
    );
  }

  void _setSearchScope(int index) {
    final followedOnly = index == 0;
    final key = followedOnly ? null : _competitions[index - 1].competitionKey;

    final followedNotifier = ref.read(teamSearchFollowedOnlyProvider.notifier);
    if (followedNotifier.state != followedOnly) {
      followedNotifier.state = followedOnly;
    }

    final competitionNotifier = ref.read(
      teamSearchCompetitionKeyProvider.notifier,
    );
    if (competitionNotifier.state != key) {
      competitionNotifier.state = key;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('チームを探す'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'チーム名で検索...',
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
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
                onTap: _setSearchScope,
                tabs: [
                  const Tab(text: 'フォロー中'),
                  ..._competitions.map((s) => Tab(text: s.displayNameJa)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _SearchResults(),
    );
  }
}

/// Shows search results from the query.
class _SearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(teamSearchResultsProvider);
    final followedOnly = ref.watch(teamSearchFollowedOnlyProvider);
    final searchQuery = ref.watch(teamSearchQueryProvider);
    final followedIds = ref.watch(followedTeamIdsProvider);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final userId = user?.uid ?? profile?.uid;

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          final emptyMessage = followedOnly
              ? (searchQuery.trim().isEmpty
                    ? 'フォロー中のチームはありません'
                    : '条件に合うフォロー中のチームはありません')
              : 'チームが見つかりませんでした';
          return _TeamSearchEmptyState(message: emptyMessage);
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final isFollowing = followedIds.contains(team.id);
            return TeamListTile(
              team: team,
              isFollowing: isFollowing,
              onTap: () => context.push('/team/${team.id}'),
              onFollowToggle: () async {
                if (userId == null) {
                  context.push('/signin');
                  return;
                }
                final repo = ref.read(userRepositoryProvider);
                if (isFollowing) {
                  await repo.unfollowTeam(
                    userId,
                    team.id,
                    competitionKey: team.competitionKey,
                  );
                } else {
                  await repo.followTeam(
                    userId,
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

class _TeamSearchEmptyState extends StatelessWidget {
  const _TeamSearchEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
