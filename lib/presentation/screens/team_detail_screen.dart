import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/utils/ics_url_builder.dart';
import '../../core/utils/local_ics_builder.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/game_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/team_providers.dart';
import '../../domain/models/game.dart';
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
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final userId = user?.uid ?? profile?.uid;

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
                  background: _TeamHeaderBackground(
                    nameJa: team.nameJa,
                    logoUrl: team.logoUrl,
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
                      if (userId == null) return;
                      final repo = ref.read(userRepositoryProvider);
                      // Pass competitionKey when available so per-competition
                      // state is updated; legacy followedTeamIds is always
                      // kept in sync inside the repository.
                      if (isFollowing) {
                        await repo.unfollowTeam(
                          userId,
                          teamId,
                          competitionKey: team.competitionKey,
                        );
                      } else {
                        await repo.followTeam(
                          userId,
                          teamId,
                          competitionKey: team.competitionKey,
                        );
                      }
                    },
                  ),
                  // Calendar sync
                  if (!useSampleData && userId != null)
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      tooltip: 'カレンダーに同期',
                      onPressed: () {
                        final url = IcsUrlBuilder.buildForTeam(userId, teamId);
                        IcsShareSheet.show(context, url);
                      },
                    ),
                  if (useSampleData)
                    gamesAsync.maybeWhen(
                      data: (games) => IconButton(
                        icon: const Icon(Icons.content_copy_outlined),
                        tooltip: games.isEmpty
                            ? 'コピーできる試合がありません'
                            : 'ローカルICSをコピー',
                        onPressed: games.isEmpty
                            ? null
                            : () => _showLocalIcsSheet(
                                context,
                                team.nameJa,
                                teamId,
                                games,
                              ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                ],
              ),
              // Games list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '直近の試合',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              gamesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    SliverToBoxAdapter(child: Center(child: Text('エラー: $e'))),
                data: (games) {
                  if (games.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _TeamDetailEmptyState(message: '直近の試合はありません'),
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

  Future<void> _showLocalIcsSheet(
    BuildContext context,
    String teamName,
    String teamId,
    List<Game> games,
  ) async {
    final icsContent = LocalIcsBuilder.buildForTeam(
      teamId: teamId,
      games: games,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _LocalIcsSheet(
        teamName: teamName,
        gameCount: games.length,
        icsContent: icsContent,
      ),
    );
  }
}

class _LocalIcsSheet extends StatelessWidget {
  const _LocalIcsSheet({
    required this.teamName,
    required this.gameCount,
    required this.icsContent,
  });

  final String teamName;
  final int gameCount;
  final String icsContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$teamName のローカルICS',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Free MVP sample mode 用に、このチームの $gameCount 試合をICSテキストとして生成しました。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  icsContent,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: icsContent));
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ローカルICSをコピーしました')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('ICSをコピー'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamHeaderBackground extends StatelessWidget {
  const _TeamHeaderBackground({required this.nameJa, required this.logoUrl});

  final String nameJa;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140, maxHeight: 96),
            child: logoUrl == null || logoUrl!.isEmpty
                ? CircleAvatar(
                    radius: 46,
                    backgroundColor: colorScheme.surface,
                    child: Text(
                      nameJa.isNotEmpty ? nameJa[0] : '?',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Image.network(
                    logoUrl!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                      radius: 46,
                      backgroundColor: colorScheme.surface,
                      child: Icon(
                        Icons.shield_outlined,
                        size: 44,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TeamDetailEmptyState extends StatelessWidget {
  const _TeamDetailEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
