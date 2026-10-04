import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_profile.dart';
import '../repositories/user_repository.dart';
import 'repository_providers.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

/// Stream of Firebase auth state (User? — null means signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  if (useSampleData) return Stream<User?>.value(null);
  return ref.watch(userRepositoryProvider).authStateChanges;
});

/// Firebase user once auth has a value.
///
/// Loading and errors are not a signed-out user. Sample mode has no Firebase
/// user; its follow actor is the sample profile.
final currentUserProvider = Provider<User?>((ref) {
  if (useSampleData) return null;
  final auth = ref.watch(authStateProvider);
  if (auth.hasError || !auth.hasValue) return null;
  return auth.value;
});

/// Uid that [userProfileProvider] watches.
///
/// Sample mode uses [SampleUserRepository.sampleUid] and does not read
/// Firebase Auth. Production loading and errors stay visible. A settled
/// signed-out session is [AsyncData] of null.
final authSessionProvider = Provider<AsyncValue<String?>>((ref) {
  if (useSampleData) {
    return const AsyncData(SampleUserRepository.sampleUid);
  }
  return authSessionFromUser(ref.watch(authStateProvider));
});

/// Maps auth to a session uid without treating loading or errors as null.
AsyncValue<String?> authSessionFromUser(AsyncValue<User?> auth) {
  if (auth.hasError) {
    return AsyncError<String?>(
      auth.error!,
      auth.stackTrace ?? StackTrace.empty,
    );
  }
  if (!auth.hasValue) return const AsyncLoading<String?>();
  return AsyncData(auth.value?.uid);
}

/// Profile stream for a resolved session.
///
/// Auth loading does not emit null. Auth errors are errors. A null uid emits
/// null and does not read Firestore, so a leftover profile cannot load.
Stream<UserProfile?> profileStreamForSession({
  required AsyncValue<String?> session,
  required Stream<UserProfile?> Function(String uid) watchProfile,
}) {
  if (session.hasError) {
    return Stream<UserProfile?>.error(
      session.error!,
      session.stackTrace ?? StackTrace.empty,
    );
  }
  if (!session.hasValue) return const Stream<UserProfile?>.empty();
  final uid = session.value;
  if (uid == null) return Stream<UserProfile?>.value(null);
  return watchProfile(uid);
}

// ── User profile ──────────────────────────────────────────────────────────────

/// Stream of the current user's Firestore profile.
///
/// Null is signed-out, or signed-in before the profile document exists.
/// Those are not read errors. Sample mode watches only the sample uid.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  if (useSampleData) {
    return ref
        .watch(userRepositoryProvider)
        .watchProfile(SampleUserRepository.sampleUid);
  }

  return profileStreamForSession(
    session: ref.watch(authSessionProvider),
    watchProfile: (uid) => ref.watch(userRepositoryProvider).watchProfile(uid),
  );
});

/// Followed team ids after auth and the profile read have settled.
///
/// Signed-out and a missing profile are an empty list. A stored empty
/// [UserProfile.followedTeamIds] is an empty list. Loading stays loading.
/// A permission or network error stays an error and is not an empty list.
final followedTeamIdsProvider = FutureProvider<List<String>>((ref) async {
  final profile = ref.watch(userProfileProvider);
  if (profile.hasError) {
    Error.throwWithStackTrace(
      profile.error!,
      profile.stackTrace ?? StackTrace.current,
    );
  }
  if (!profile.hasValue) {
    final resolved = await ref.watch(userProfileProvider.future);
    return resolved?.followedTeamIds ?? const <String>[];
  }
  return profile.value?.followedTeamIds ?? const <String>[];
});

/// Who may follow or unfollow.
///
/// A sample session uses the settled sample profile uid. Production uses only
/// the Firebase uid. A profile document is not a production session, including
/// a previous profile still visible while auth is loading.
String? followActorId({
  required bool sampleSession,
  required String? firebaseUid,
  required bool profileSettled,
  required String? profileUid,
}) {
  if (!sampleSession) return firebaseUid;
  if (!profileSettled) return null;
  return profileUid;
}

/// Follow button state shared by search, league, and team detail.
class FollowInteraction {
  const FollowInteraction({
    required this.userId,
    required this.followedIds,
    required this.profileFailed,
  });

  /// Null when this session must not write a follow.
  final String? userId;

  /// Null while the follow list is loading or failed. Empty is a known empty
  /// list, not a failure.
  final List<String>? followedIds;

  final bool profileFailed;

  bool isFollowing(String teamId) => followedIds?.contains(teamId) ?? false;
}

FollowInteraction watchFollowInteraction(WidgetRef ref) {
  final sampleSession =
      useSampleData ||
      ref.watch(userRepositoryProvider) is SampleUserRepository;
  final profile = ref.watch(userProfileProvider);
  final follows = ref.watch(followedTeamIdsProvider);
  final profileSettled =
      profile.hasValue && !profile.isLoading && !profile.hasError;
  return FollowInteraction(
    userId: followActorId(
      sampleSession: sampleSession,
      firebaseUid: ref.watch(currentUserProvider)?.uid,
      profileSettled: profileSettled,
      profileUid: profileSettled ? profile.value?.uid : null,
    ),
    followedIds: follows.hasError ? null : follows.asData?.value,
    profileFailed: profile.hasError || follows.hasError,
  );
}
