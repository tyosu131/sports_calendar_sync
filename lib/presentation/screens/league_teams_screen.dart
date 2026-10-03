import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/sports_registry.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/team_providers.dart';
import '../../domain/models/sport_definition.dart';
import '../../domain/models/team.dart';
import '../widgets/team_list_tile.dart';

/// Teams for one registry competition, opened from the in-sport league list.
///
/// Follow and unfollow use the same user repository calls as team search.
class LeagueTeamsScreen extends ConsumerWidget {
  const LeagueTeamsScreen({super.key, required this.competitionKey});

  final String competitionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = SportsRegistry.findByKey(competitionKey);
    if (definition == null || !definition.enabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('リーグ')),
        body: const _LeagueTeamsMessage(message: 'このリーグは見つかりません'),
      );
    }

    final teamsAsync = ref.watch(teamsByCompetitionProvider(competitionKey));
    return Scaffold(
      appBar: AppBar(title: Text(definition.displayNameJa)),
      body: teamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LeagueTeamsMessage(
          message: 'エラー: $error',
          actionLabel: '再試行',
          onAction: () =>
              ref.invalidate(teamsByCompetitionProvider(competitionKey)),
        ),
        data: (teams) {
          if (teams.isEmpty) {
            return _LeagueTeamsMessage(
              message: 'このリーグのチームはまだありません',
              detail: 'チームが登録されると、ここに表示されます。',
              actionLabel: 'チームを探す',
              onAction: () => context.push('/search'),
            );
          }
          return _LeagueTeamList(definition: definition, teams: teams);
        },
      ),
    );
  }
}

class _LeagueTeamList extends ConsumerWidget {
  const _LeagueTeamList({required this.definition, required this.teams});

  final SportDefinition definition;
  final List<Team> teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followedIds = ref.watch(followedTeamIdsProvider);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final userId = user?.uid ?? profile?.uid;

    return ListView.builder(
      key: ValueKey('league-teams-${definition.competitionKey}'),
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
  }
}

class _LeagueTeamsMessage extends StatelessWidget {
  const _LeagueTeamsMessage({
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              Icon(Icons.groups_outlined, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
