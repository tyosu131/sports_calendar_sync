import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/sports_registry.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/game_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/team_providers.dart';
import '../../domain/models/sport_definition.dart';
import '../../domain/models/team.dart';
import '../../domain/policies/league_browse_presentation.dart';
import '../../domain/policies/team_display_name_policy.dart';
import '../../domain/policies/team_initial.dart';
import '../theme/league_browse_accents.dart';

/// Teams for one registry competition, opened from the in-sport league list.
///
/// Follow and unfollow use the same user repository calls as team search.
/// Cards use a stable accent, not an official kit color.
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
          return _LeagueTeamGrid(definition: definition, teams: teams);
        },
      ),
    );
  }
}

class _LeagueTeamGrid extends ConsumerWidget {
  const _LeagueTeamGrid({required this.definition, required this.teams});

  final SportDefinition definition;
  final List<Team> teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followedIds = ref.watch(followedTeamIdsProvider);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final userId = user?.uid ?? profile?.uid;
    final gamesAsync = ref.watch(
      upcomingGamesForTeamIdsProvider(
        leagueTeamIdsKey(teams.map((team) => team.id)),
      ),
    );
    final games = gamesAsync.asData?.value;

    return GridView.builder(
      key: ValueKey('league-teams-${definition.competitionKey}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        final isFollowing = followedIds.contains(team.id);
        final next = games == null ? null : nextMatchForTeam(team, games);
        return _LeagueTeamCard(
          team: team,
          isFollowing: isFollowing,
          next: next,
          gamesSettled: gamesAsync.hasValue || gamesAsync.hasError,
          gamesFailed: gamesAsync.hasError,
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

class _LeagueTeamCard extends StatelessWidget {
  const _LeagueTeamCard({
    required this.team,
    required this.isFollowing,
    required this.next,
    required this.gamesSettled,
    required this.gamesFailed,
    required this.onTap,
    required this.onFollowToggle,
  });

  final Team team;
  final bool isFollowing;
  final LeagueTeamNextMatch? next;
  final bool gamesSettled;
  final bool gamesFailed;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;

  @override
  Widget build(BuildContext context) {
    final fullName = teamDisplayNames.teamName(team);
    final shortName = leagueTeamCardLabelForTeam(team);
    final accent = leagueBrowseAccent(team.id);
    final followLabel = isFollowing ? 'フォロー中' : 'フォロー';
    final matchLine = !gamesSettled
        ? null
        : next == null
        ? (gamesFailed ? null : '次の試合は未定')
        : next!.opponent;

    return Material(
      key: ValueKey('league-team-card-${team.id}'),
      color: accent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Text(
                      teamInitial(fullName),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _FollowPill(
                    label: followLabel,
                    filled: isFollowing,
                    tooltip: isFollowing ? 'フォロー解除' : 'フォローする',
                    onPressed: onFollowToggle,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                shortName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              if (matchLine != null)
                Text(
                  matchLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (next != null)
                Text(
                  next!.when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowPill extends StatelessWidget {
  const _FollowPill({
    required this.label,
    required this.filled,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(filled ? Icons.favorite : Icons.favorite_border, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
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
