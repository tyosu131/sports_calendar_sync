import 'package:flutter/material.dart';

import '../../domain/models/game.dart';
import '../../domain/policies/competition_display_policy.dart';
import '../../domain/policies/followed_fixture_place.dart';
import '../../domain/policies/game_presentation_policy.dart';
import '../../domain/policies/kickoff_clock.dart';
import '../../domain/policies/team_display_name_policy.dart';
import '../../domain/policies/team_presentation_policy.dart';
import '../theme/competition_vs_frame.dart';
import 'competition_badge.dart';
import 'competition_vs_frame.dart';
import 'drawn_place_icons.dart';
import 'game_presentation_scope.dart';
import 'game_status_chip.dart';
import 'team_presentation_badge.dart';

/// Displays a single game/match as a card.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    this.homeTeamLogoUrlFallback,
    this.awayTeamLogoUrlFallback,
    this.perspectiveTeamIds = const [],
  });

  final Game game;
  final String? homeTeamLogoUrlFallback;
  final String? awayTeamLogoUrlFallback;

  /// Canonical team ids used to place the stadium / travel cue.
  ///
  /// Home and sport-home pass followed team ids. A team schedule passes
  /// that one team. Each matching side shows its own cue.
  final List<String> perspectiveTeamIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final competition = CompetitionDisplayPolicy.forKey(game.competitionKey);
    final places = fixturePlaceForPerspective(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.awayTeamId,
      perspectiveTeamIds: perspectiveTeamIds,
    );
    final showStatus = GameStatusPresentation.forStatus(game.status) != null;
    final kickoff = displayedKickoff(
      startTimeUtc: game.startTimeUtcDateTime,
      providerTimezone: game.timezone,
      venueName: game.venue,
    );
    final frames = competitionVsFrameColors(game.competitionKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (competition != null) ...[
              CompetitionBadge(competition: competition),
              const SizedBox(height: 8),
            ],
            // Kickoff is JST from startTimeUTC. No authoritative venue
            // timezone is stored, so provider `timezone` is not displayed.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kickoff.time,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (kickoff.isToday) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '今日',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              kickoff.date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showStatus) ...[
                  const SizedBox(width: 8),
                  GameStatusChip(status: game.status),
                ],
              ],
            ),
            if (places.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (places.contains(FollowedFixturePlace.stadium))
                    const _FollowedPlaceChip(
                      place: FollowedFixturePlace.stadium,
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  if (places.contains(FollowedFixturePlace.travel))
                    const _FollowedPlaceChip(
                      place: FollowedFixturePlace.travel,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Teams row. Home and away frames differ in color and shape.
            // The card surface stays the theme surface.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CompetitionVsSide(
                      side: CompetitionVsSideKind.home,
                      color: frames.home,
                      child: _TeamSide(
                        name: teamDisplayNames.homeName(game),
                        nameColor: competitionVsFrameTextColor(frames.home),
                        logoUrl: resolveGameTeamLogoUrl(
                          game.homeTeamLogoUrl,
                          homeTeamLogoUrlFallback ??
                              GamePresentationScope.logo(context, game, true),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(child: _ScoreOrVs(game: game)),
                  ),
                  Expanded(
                    child: CompetitionVsSide(
                      side: CompetitionVsSideKind.away,
                      color: frames.away,
                      child: _TeamSide(
                        name: teamDisplayNames.awayName(game),
                        nameColor: competitionVsFrameTextColor(frames.away),
                        logoUrl: resolveGameTeamLogoUrl(
                          game.awayTeamLogoUrl,
                          awayTeamLogoUrlFallback ??
                              GamePresentationScope.logo(context, game, false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Venue
            if (visibleVenue(game.venue) case final venue?) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  VenuePinMark(
                    color: theme.colorScheme.onSurfaceVariant,
                    hole: theme.colorScheme.surface,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Broadcast platforms
            if (game.broadcastPlatforms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: game.broadcastPlatforms
                    .map((b) => _PlatformChip(platform: b.platform))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Metadata authority never implies permission to display a third-party logo.
String? resolveGameTeamLogoUrl(String? gameLogoUrl, String? canonicalLogoUrl) {
  return publicTeamLogoUrl(gameLogoUrl) ?? publicTeamLogoUrl(canonicalLogoUrl);
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.name,
    required this.nameColor,
    required this.logoUrl,
  });

  final String name;
  final Color nameColor;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GameTeamLogo(name: name, logoUrl: logoUrl),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: nameColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _GameTeamLogo extends StatelessWidget {
  const _GameTeamLogo({required this.name, required this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) => TeamPresentationBadge(
    size: 48,
    displayName: name,
    logoUrl: logoUrl,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
  );
}

class _FollowedPlaceChip extends StatelessWidget {
  const _FollowedPlaceChip({required this.place});

  final FollowedFixturePlace place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stadium = place == FollowedFixturePlace.stadium;
    final background = stadium
        ? scheme.primaryContainer
        : scheme.tertiaryContainer;
    final foreground = stadium
        ? scheme.onPrimaryContainer
        : scheme.onTertiaryContainer;

    return Semantics(
      key: Key(
        stadium
            ? 'followed-fixture-place-stadium'
            : 'followed-fixture-place-travel',
      ),
      container: true,
      label: followedFixturePlaceSemanticsLabel(place),
      child: ExcludeSemantics(
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: foreground.withValues(alpha: 0.72)),
          ),
          child: stadium
              ? StadiumCueMark(color: foreground)
              : TransitCueMark(color: foreground, cutout: background),
        ),
      ),
    );
  }
}

class _ScoreOrVs extends StatelessWidget {
  const _ScoreOrVs({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldShowScore =
        (game.status == GameStatus.finished ||
            game.status == GameStatus.live) &&
        game.homeScore != null &&
        game.awayScore != null;

    if (shouldShowScore) {
      return Text(
        formatScore(game.homeScore, game.awayScore)!,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Text(
      'vs',
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.platform});
  final String platform;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        platform,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
