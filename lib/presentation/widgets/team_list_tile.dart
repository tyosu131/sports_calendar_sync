import 'package:flutter/material.dart';

import '../../domain/models/team.dart';
import '../../domain/policies/team_display_name_policy.dart';
import '../../domain/policies/team_presentation_policy.dart';
import 'team_presentation_badge.dart';

/// A list tile for displaying a team with follow/unfollow action.
class TeamListTile extends StatelessWidget {
  const TeamListTile({
    super.key,
    required this.team,
    required this.isFollowing,
    required this.onFollowToggle,
    this.onTap,
  });

  final Team team;
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: TeamPresentationBadge(
          size: 52,
          logoUrl: teamPresentationLogo(team),
          displayName: teamDisplayNames.teamName(team),
        ),
        title: Text(
          teamDisplayNames.teamName(team),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isFollowing ? Icons.favorite : Icons.favorite_border,
            color: isFollowing ? theme.colorScheme.primary : null,
          ),
          tooltip: isFollowing ? 'フォロー解除' : 'フォローする',
          onPressed: onFollowToggle,
        ),
      ),
    );
  }
}
