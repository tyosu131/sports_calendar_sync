import 'package:flutter/material.dart';

import '../../domain/models/game.dart';
import '../../domain/policies/game_presentation_policy.dart';

class GameStatusChip extends StatelessWidget {
  const GameStatusChip({super.key, required this.status});
  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = GameStatusPresentation.forStatus(status);
    if (presentation == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = switch (presentation.colorRole) {
      GameStatusColorRole.live => theme.colorScheme.error,
      GameStatusColorRole.finished => theme.colorScheme.secondary,
      GameStatusColorRole.postponed => theme.colorScheme.tertiary,
      GameStatusColorRole.cancelled => theme.colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        presentation.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
