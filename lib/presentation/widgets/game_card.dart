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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
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
                Text(
                  DateTimeUtils.formatJst(game.startTimeUtcDateTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: game.status),
              ],
            ),
            const SizedBox(height: 12),
            // Teams row
            Row(
              children: [
                Expanded(
                  child: Text(
                    game.homeTeamNameJa,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ScoreOrVs(game: game),
                ),
                Expanded(
                  child: Text(
                    game.awayTeamNameJa,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Venue
            if (game.venue != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    game.venue!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _ScoreOrVs extends StatelessWidget {
  const _ScoreOrVs({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (game.status == GameStatus.finished ||
        game.status == GameStatus.live) {
      return Text(
        '${game.homeScore ?? '-'} - ${game.awayScore ?? '-'}',
        style: theme.textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
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
        color = theme.colorScheme.outline;
        label = '終了';
      case GameStatus.postponed:
        color = Colors.orange;
        label = '延期';
      case GameStatus.cancelled:
        color = Colors.grey;
        label = '中止';
      case GameStatus.scheduled:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
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
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
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
