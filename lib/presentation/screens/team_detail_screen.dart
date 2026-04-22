import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ics_url_builder.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/game_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/team_providers.dart';
import '../widgets/game_card.dart';
import '../widgets/ics_share_sheet.dart';

/// Detail screen for a single team: shows schedule + follow/sync actions.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamByIdProvider(teamId));
    final gamesAsync = ref.watch(upcomingGamesForTeamProvider(teamId));
    final followedIds = ref.watch(followedTeamIdsProvider);
    final user = ref.watch(currentUserProvider);

    final isFollowing = followedIds.contains(teamId);

    return Scaffold(
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (team) {
          if (team == null) {
            return const Center(child: Text('チームが見つかりませんでした'));
          }
          return CustomScrollView(
            slivers: [
              // App bar with team logo
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(team.nameJa),
                  background: team.logoUrl != null
                      ? Image.network(
                          team.logoUrl!,
                          fit: BoxFit.contain,
                        )
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Center(
                            child: Text(
                              team.nameJa[0],
                              style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
                actions: [
                  // Follow/unfollow
                  IconButton(
                    icon: Icon(
                      isFollowing ? Icons.favorite : Icons.favorite_border,
                      color: isFollowing ? Colors.red : null,
                    ),
                    tooltip: isFollowing ? 'フォロー解除' : 'フォローする',
                    onPressed: () async {
                      if (user == null) return;
                      final repo = ref.read(userRepositoryProvider);
                      if (isFollowing) {
                        await repo.unfollowTeam(user.uid, teamId);
                      } else {
                        await repo.followTeam(user.uid, teamId);
                      }
                    },
                  ),
                  // Calendar sync
                  if (user != null)
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      tooltip: 'カレンダーに同期',
                      onPressed: () {
                        final url =
                            IcsUrlBuilder.buildForTeam(user.uid, teamId);
                        IcsShareSheet.show(context, url);
                      },
                    ),
                ],
              ),
              // Games list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '直近の試合',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              gamesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('エラー: $e')),
                ),
                data: (games) {
                  if (games.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('直近の試合はありません')),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => GameCard(game: games[index]),
                      childCount: games.length,
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }
}
