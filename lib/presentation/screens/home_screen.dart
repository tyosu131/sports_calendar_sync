import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/ics_url_builder.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/game_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/team_providers.dart';
import '../../domain/models/team.dart';
import '../widgets/game_card.dart';
import '../widgets/ics_share_sheet.dart';

/// Home screen: shows upcoming games for the user's followed teams.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final gamesAsync = ref.watch(upcomingGamesForFollowedTeamsProvider);
    final followedTeamsAsync = ref.watch(followedTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('スポーツカレンダー'),
        actions: [
          // In-app calendar view (not iCalendar sync).
          userAsync.whenOrNull(
                data: (profile) => profile != null
                    ? IconButton(
                        icon: const Icon(Icons.event_note_outlined),
                        tooltip: 'スケジュールを表示',
                        onPressed: () => context.push('/schedule'),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          // Calendar sync button
          userAsync.whenOrNull(
                data: (profile) => !useSampleData && profile != null
                    ? IconButton(
                        icon: const Icon(Icons.calendar_month),
                        tooltip: 'カレンダーに同期',
                        onPressed: () {
                          final url = IcsUrlBuilder.buildForUser(profile.uid);
                          IcsShareSheet.show(context, url);
                        },
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (profile) {
          if (profile == null) {
            return const _SignInPrompt();
          }
          return _HomeContent(
            gamesAsync: gamesAsync,
            followedTeamsAsync: followedTeamsAsync,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/search'),
        icon: const Icon(Icons.add),
        label: const Text('チームを追加'),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.gamesAsync,
    required this.followedTeamsAsync,
  });

  final AsyncValue gamesAsync;
  final AsyncValue followedTeamsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return followedTeamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          return const _EmptyFollowedTeams();
        }
        return gamesAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            children: [
              _FollowedTeamsSection(teams: teams),
              const SizedBox(height: 80),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (games) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(followedTeamsProvider);
                ref.invalidate(upcomingGamesForFollowedTeamsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 100),
                children: [
                  _FollowedTeamsSection(teams: teams),
                  if (games.isEmpty)
                    const _NoUpcomingGames()
                  else
                    ...games.map((game) => GameCard(game: game)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FollowedTeamsSection extends StatelessWidget {
  const _FollowedTeamsSection({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'フォロー中のチーム',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: teams.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final team = teams[index];
                return _FollowedTeamCard(
                  team: team,
                  backgroundColor: colorScheme.surface,
                  borderColor: colorScheme.outlineVariant,
                  onTap: () => context.push('/team/${team.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowedTeamCard extends StatelessWidget {
  const _FollowedTeamCard({
    required this.team,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final Team team;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logoUrl = team.logoUrl;

    return SizedBox(
      width: 196,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: logoUrl == null || logoUrl.isEmpty
                      ? const Icon(Icons.shield_outlined, size: 24)
                      : ClipOval(
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.shield_outlined, size: 24),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.nameJa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        team.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoUpcomingGames extends StatelessWidget {
  const _NoUpcomingGames();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '直近の試合はありません',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'フォロー中チームの試合が追加されると、ここに表示されます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFollowedTeams extends StatelessWidget {
  const _EmptyFollowedTeams();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports, size: 72, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'フォローしているチームがありません',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '「チームを追加」からお気に入りのチームを登録してください。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search),
                label: const Text('チームを探す'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 72, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'サインインが必要です',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/signin'),
                child: const Text('サインイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
