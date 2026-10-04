import 'dart:async';

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
/// Null is either signed-out, or signed-in before the profile document
/// exists. Those are not the same session. Sample mode watches only the
/// sample uid.
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

/// Signed-in, and `users/{uid}` has no document.
///
/// This is not signed-out and not an empty follow list. Follow writes against
/// a missing document fail, so the session must not attempt one.
class ProfileDocumentMissing implements Exception {
  const ProfileDocumentMissing();

  @override
  String toString() => 'プロフィールを確認できません';
}

/// Followed team ids after auth and the profile read have settled for the
/// same uid.
///
/// Signed-out is an empty list. A stored empty [UserProfile.followedTeamIds]
/// is an empty list. Loading stays loading, including while a previous user's
/// profile is still the reload value. A permission, network, or missing
/// document stays an error and is not an empty list.
final followedTeamIdsProvider = FutureProvider<List<String>>((ref) async {
  final sampleSession = _sampleSession(ref);
  final session = _sessionFor(ref, sampleSession);
  final profile = ref.watch(userProfileProvider);
  final decision = settleFollowList(
    sampleSession: sampleSession,
    session: session,
    profile: profile,
  );
  switch (decision) {
    case FollowListReady(:final ids):
      return ids;
    case FollowListFailed(:final error, :final stackTrace):
      Error.throwWithStackTrace(error, stackTrace);
    case FollowListPending():
      // The profile future completes on the next emission, not on the
      // previous value Riverpod keeps during reload. A session change
      // rebuilds this provider and drops the in-flight result.
      await ref.watch(userProfileProvider.future);
      final again = settleFollowList(
        sampleSession: sampleSession,
        session: _sessionFor(ref, sampleSession),
        profile: ref.watch(userProfileProvider),
      );
      switch (again) {
        case FollowListReady(:final ids):
          return ids;
        case FollowListFailed(:final error, :final stackTrace):
          Error.throwWithStackTrace(error, stackTrace);
        case FollowListPending():
          return await Completer<List<String>>().future;
      }
  }
});

bool _sampleSession(Ref ref) {
  return useSampleData ||
      ref.watch(userRepositoryProvider) is SampleUserRepository;
}

AsyncValue<String?> _sessionFor(Ref ref, bool sampleSession) {
  if (sampleSession) return const AsyncData(SampleUserRepository.sampleUid);
  return ref.watch(authSessionProvider);
}

/// Who may follow or unfollow.
///
/// A sample session uses the settled sample profile uid. Production uses the
/// Firebase uid only when that same uid's profile is settled. A previous
/// profile, a missing document, auth loading, and auth errors are not an actor.
String? followActorId({
  required bool sampleSession,
  required String? firebaseUid,
  required bool profileReady,
  required String? profileUid,
}) {
  if (!profileReady || profileUid == null) return null;
  if (sampleSession) return profileUid;
  if (firebaseUid == null || firebaseUid != profileUid) return null;
  return firebaseUid;
}

/// Follow list after discarding a profile that belongs to another session.
sealed class FollowListDecision {
  const FollowListDecision();
}

class FollowListPending extends FollowListDecision {
  const FollowListPending();
}

class FollowListReady extends FollowListDecision {
  const FollowListReady(this.ids, this.profile);

  final List<String> ids;
  final UserProfile? profile;
}

class FollowListFailed extends FollowListDecision {
  const FollowListFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Resolves follows for the session that is current now.
///
/// [profile] may still expose the previous user's document while it reloads.
/// That value is pending, not a follow list, and it is not paired with the
/// new uid.
FollowListDecision settleFollowList({
  required bool sampleSession,
  required AsyncValue<String?> session,
  required AsyncValue<UserProfile?> profile,
}) {
  final expectedUid = sampleSession
      ? SampleUserRepository.sampleUid
      : _settledUid(session);
  if (!sampleSession && session.hasError) {
    return FollowListFailed(
      session.error!,
      session.stackTrace ?? StackTrace.empty,
    );
  }
  if (expectedUid == _uidPending) return const FollowListPending();

  // AsyncError has no value. Checking !hasValue first would hide the error
  // as loading.
  if (profile.hasError) {
    return FollowListFailed(
      profile.error!,
      profile.stackTrace ?? StackTrace.empty,
    );
  }
  if (profile.isLoading || !profile.hasValue) return const FollowListPending();

  final value = profile.value;
  if (expectedUid == null) {
    if (value != null) return const FollowListPending();
    return const FollowListReady(<String>[], null);
  }
  if (value == null) {
    return FollowListFailed(const ProfileDocumentMissing(), StackTrace.current);
  }
  if (value.uid != expectedUid) return const FollowListPending();
  return FollowListReady(value.followedTeamIds, value);
}

const _uidPending = Object();

Object? _settledUid(AsyncValue<String?> session) {
  if (session.isLoading || !session.hasValue || session.hasError) {
    return _uidPending;
  }
  return session.value;
}

/// What Home may show for the current account.
enum AccountGateKind { loading, failed, signedOut, missingProfile, ready }

class AccountGate {
  const AccountGate._(this.kind, {this.profile, this.error});

  const AccountGate.loading() : this._(AccountGateKind.loading);

  const AccountGate.failed(Object error)
    : this._(AccountGateKind.failed, error: error);

  const AccountGate.signedOut() : this._(AccountGateKind.signedOut);

  const AccountGate.missingProfile() : this._(AccountGateKind.missingProfile);

  const AccountGate.ready(UserProfile profile)
    : this._(AccountGateKind.ready, profile: profile);

  final AccountGateKind kind;
  final UserProfile? profile;
  final Object? error;
}

AccountGate accountGate({
  required bool sampleSession,
  required AsyncValue<String?> session,
  required AsyncValue<UserProfile?> profile,
}) {
  final decision = settleFollowList(
    sampleSession: sampleSession,
    session: session,
    profile: profile,
  );
  switch (decision) {
    case FollowListPending():
      return const AccountGate.loading();
    case FollowListFailed(:final error):
      if (error is ProfileDocumentMissing) {
        return const AccountGate.missingProfile();
      }
      return AccountGate.failed(error);
    case FollowListReady(:final profile):
      if (profile == null) return const AccountGate.signedOut();
      return AccountGate.ready(profile);
  }
}

/// Follow button state shared by search, league, and team detail.
class FollowInteraction {
  const FollowInteraction({
    required this.userId,
    required this.followedIds,
    required this.profileFailed,
    required this.signedOut,
  });

  /// Null when this session must not write a follow.
  final String? userId;

  /// Null while the follow list is loading, failed, or not for this uid.
  /// Empty is a known empty list, not a failure.
  final List<String>? followedIds;

  final bool profileFailed;

  /// Settled signed-out. Missing documents and auth errors are not this.
  final bool signedOut;

  bool isFollowing(String teamId) => followedIds?.contains(teamId) ?? false;
}

final followSessionProvider = Provider<FollowInteraction>((ref) {
  final sampleSession = _sampleSession(ref);
  final session = _sessionFor(ref, sampleSession);
  final profile = ref.watch(userProfileProvider);
  return followInteractionFrom(
    sampleSession: sampleSession,
    session: session,
    profile: profile,
  );
});

FollowInteraction followInteractionFrom({
  required bool sampleSession,
  required AsyncValue<String?> session,
  required AsyncValue<UserProfile?> profile,
}) {
  final decision = settleFollowList(
    sampleSession: sampleSession,
    session: session,
    profile: profile,
  );
  final sessionUid = sampleSession
      ? SampleUserRepository.sampleUid
      : (session.hasValue && !session.isLoading && !session.hasError
            ? session.value
            : null);
  switch (decision) {
    case FollowListReady(:final ids, :final profile):
      return FollowInteraction(
        userId: followActorId(
          sampleSession: sampleSession,
          firebaseUid: sessionUid,
          profileReady: profile != null,
          profileUid: profile?.uid,
        ),
        followedIds: ids,
        profileFailed: false,
        signedOut: profile == null,
      );
    case FollowListFailed():
      return const FollowInteraction(
        userId: null,
        followedIds: null,
        profileFailed: true,
        signedOut: false,
      );
    case FollowListPending():
      return const FollowInteraction(
        userId: null,
        followedIds: null,
        profileFailed: false,
        signedOut: false,
      );
  }
}

final accountGateProvider = Provider<AccountGate>((ref) {
  final sampleSession = _sampleSession(ref);
  return accountGate(
    sampleSession: sampleSession,
    session: _sessionFor(ref, sampleSession),
    profile: ref.watch(userProfileProvider),
  );
});

FollowInteraction watchFollowInteraction(WidgetRef ref) {
  return ref.watch(followSessionProvider);
}
