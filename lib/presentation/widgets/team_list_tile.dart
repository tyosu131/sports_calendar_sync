import 'package:flutter/material.dart';

import '../../domain/models/team.dart';

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
        leading: _TeamLogo(logoUrl: team.logoUrl, nameJa: team.nameJa),
        title: Text(
          team.nameJa,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          team.nameEn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({this.logoUrl, required this.nameJa});
  final String? logoUrl;
  final String nameJa;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      nameJa.isNotEmpty ? nameJa[0] : '?',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: SizedBox(
            width: 46,
            height: 46,
            child: Image.network(
              logoUrl!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: fallback),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: fallback,
    );
  }
}
