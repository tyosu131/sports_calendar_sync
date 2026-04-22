import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/ics_url_builder.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/game_providers.dart';
import '../../data/providers/team_providers.dart';
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
          // Calendar sync button
          userAsync.whenOrNull(
            data: (profile) => profile != null
                ? IconButton(
                    icon: const Icon(Icons.calendar_month),
                    tooltip: 'カレンダーに同期',
                    onPressed: () {
                      final url = IcsUrlBuilder.buildForUser(profile.uid);
                      IcsShareSheet.show(context, url);
                    },
                  )
                : null,
          ) ?? const SizedBox.shrink(),
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
    final followedTeams = ref.watch(followedTeamsProvider);

    return followedTeams.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          return const _EmptyFollowedTeams();
        }
        return gamesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (games) {
            if (games.isEmpty) {
              return const Center(
                child: Text(
                  '直近の試合はありません',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(upcomingGamesForFollowedTeamsProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return GameCard(game: games[index]);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyFollowedTeams extends StatelessWidget {
  const _EmptyFollowedTeams();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'フォローしているチームがありません',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '「チームを追加」からお気に入りのチームを登録してください。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'サインインが必要です',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/signin'),
              child: const Text('サインイン'),
            ),
          ],
        ),
      ),
    );
  }
}
