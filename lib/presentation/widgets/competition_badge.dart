import 'package:flutter/material.dart';

import '../../domain/policies/competition_display_policy.dart';

class CompetitionBadge extends StatelessWidget {
  const CompetitionBadge({super.key, required this.competitionKey});

  final String? competitionKey;

  @override
  Widget build(BuildContext context) {
    final competition = CompetitionDisplayPolicy.forKey(competitionKey);
    if (competition == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        competition.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
