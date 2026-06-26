import 'package:flutter/material.dart';

import '../../core/utils/date_time_utils.dart';
import '../../domain/models/game.dart';

/// Displays a single game/match as a card.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = DateTimeUtils.isToday(game.startTimeUtcDateTime);

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
            // Date/time row
            Row(
              children: [
                if (isToday)
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
                if (isToday) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateTimeUtils.formatJst(game.startTimeUtcDateTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: game.status),
              ],
            ),
            const SizedBox(height: 12),
            // Teams row
            Row(
              children: [
                Expanded(
                  child: _TeamSide(
                    name: game.homeTeamNameJa,
                    logoUrl: game.homeTeamLogoUrl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ScoreOrVs(game: game),
                ),
                Expanded(
                  child: _TeamSide(
                    name: game.awayTeamNameJa,
                    logoUrl: game.awayTeamLogoUrl,
                  ),
                ),
              ],
            ),
            // Venue
            if (game.venue != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game.venue!,
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

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.name, required this.logoUrl});

  final String name;
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
  Widget build(BuildContext context) {
    final fallback = Text(
      name.isEmpty ? '?' : String.fromCharCode(name.runes.first),
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: logoUrl == null || logoUrl!.isEmpty
          ? fallback
          : ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.network(
                  logoUrl!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.shield_outlined, size: 24),
                ),
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
        '${game.homeScore} - ${game.awayScore}',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    String label;
    switch (status) {
      case GameStatus.live:
        color = Colors.red;
        label = 'LIVE';
      case GameStatus.finished:
        color = theme.colorScheme.secondary;
        label = '終了';
      case GameStatus.postponed:
        color = theme.colorScheme.tertiary;
        label = '延期';
      case GameStatus.cancelled:
        color = theme.colorScheme.outline;
        label = '中止';
      case GameStatus.scheduled:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
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
