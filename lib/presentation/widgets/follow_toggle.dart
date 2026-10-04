import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_providers.dart';
import '../../data/providers/repository_providers.dart';

/// Writes a follow only when the session and the follow list are both known.
///
/// A profile or follow-list error is not signed-out and does not open sign-in.
/// Loading does not write. A missing actor opens sign-in except on team detail,
/// which already ignores that tap.
Future<void> toggleFollow(
  BuildContext context,
  WidgetRef ref,
  FollowInteraction session,
  String teamId,
  String? competitionKey, {
  bool openSignIn = true,
}) async {
  if (session.profileFailed) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('フォロー状態を確認できません')));
    return;
  }
  if (session.followedIds == null) return;
  final userId = session.userId;
  if (userId == null) {
    if (openSignIn) context.push('/signin');
    return;
  }
  final repository = ref.read(userRepositoryProvider);
  if (session.isFollowing(teamId)) {
    await repository.unfollowTeam(
      userId,
      teamId,
      competitionKey: competitionKey,
    );
  } else {
    await repository.followTeam(userId, teamId, competitionKey: competitionKey);
  }
}
