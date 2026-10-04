import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/repository_providers.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';

void main() {
  test('signed-out is a null profile and an empty follow list', () async {
    final repository = _ScriptedUsers(
      (uid) => Stream<UserProfile?>.value(
        UserProfile(uid: uid, email: 'leftover@example.com'),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        userRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    _keep(container);

    expect(await container.read(userProfileProvider.future), isNull);
    expect(repository.watched, isEmpty);
    expect(await container.read(followedTeamIdsProvider.future), isEmpty);
    expect(container.read(followedTeamIdsProvider).hasError, isFalse);
    expect(container.read(currentUserProvider), isNull);
    final session = container.read(followSessionProvider);
    expect(session.signedOut, isTrue);
    expect(session.userId, isNull);
    expect(session.followedIds, isEmpty);
  });

  test('auth loading is not a profile error or an empty follow list', () async {
    final auth = StreamController<User?>();
    addTearDown(auth.close);
    final repository = _ScriptedUsers(
      (uid) => Stream<UserProfile?>.error(StateError('should not read')),
    );
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => auth.stream),
        userRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(userProfileProvider, (_, _) {});
    container.listen(followedTeamIdsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final profile = container.read(userProfileProvider);
    final follows = container.read(followedTeamIdsProvider);
    expect(profile.isLoading, isTrue);
    expect(profile.hasError, isFalse);
    expect(profile.hasValue, isFalse);
    expect(follows.isLoading, isTrue);
    expect(follows.hasError, isFalse);
    expect(follows.asData, isNull);
    expect(repository.watched, isEmpty);
  });

  test('auth failure is not signed-out and not zero follows', () async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream<User?>.error(StateError('permission-denied')),
        ),
        userRepositoryProvider.overrideWithValue(
          _ScriptedUsers((uid) => Stream<UserProfile?>.value(null)),
        ),
      ],
    );
    addTearDown(container.dispose);
    _keep(container);

    await expectLater(
      container.read(userProfileProvider.future),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'permission-denied',
        ),
      ),
    );
    await expectLater(
      container.read(followedTeamIdsProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(container.read(followedTeamIdsProvider).asData, isNull);
    expect(container.read(currentUserProvider), isNull);
  });

  test('a missing profile is not signed-out and cannot follow', () async {
    final container = _signedIn(Stream<UserProfile?>.value(null));
    addTearDown(container.dispose);
    _keep(container);

    expect(await container.read(userProfileProvider.future), isNull);
    expect(container.read(userProfileProvider).hasError, isFalse);
    await expectLater(
      container.read(followedTeamIdsProvider.future),
      throwsA(isA<ProfileDocumentMissing>()),
    );
    final session = container.read(followSessionProvider);
    expect(session.signedOut, isFalse);
    expect(session.profileFailed, isTrue);
    expect(session.userId, isNull);
    expect(session.followedIds, isNull);
    expect(
      accountGate(
        sampleSession: false,
        session: const AsyncData('uid'),
        profile: const AsyncData<UserProfile?>(null),
      ).kind,
      AccountGateKind.missingProfile,
    );
  });

  test('an empty followedTeamIds list is a normal empty state', () async {
    final container = _signedIn(
      Stream<UserProfile?>.value(
        const UserProfile(
          uid: 'uid',
          email: 'user@example.com',
          followedTeamIds: [],
        ),
      ),
    );
    addTearDown(container.dispose);
    _keep(container);

    expect(await container.read(followedTeamIdsProvider.future), isEmpty);
    expect(container.read(followedTeamIdsProvider).hasError, isFalse);
    final session = container.read(followSessionProvider);
    expect(session.userId, 'uid');
    expect(session.followedIds, isEmpty);
    expect(session.signedOut, isFalse);
    expect(session.profileFailed, isFalse);
  });

  test('profile loading is not a profile error', () async {
    final profiles = StreamController<UserProfile?>();
    addTearDown(profiles.close);
    final container = _signedIn(profiles.stream);
    addTearDown(container.dispose);
    container.listen(userProfileProvider, (_, _) {});
    container.listen(followedTeamIdsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(userProfileProvider).isLoading, isTrue);
    expect(container.read(userProfileProvider).hasError, isFalse);
    expect(container.read(followedTeamIdsProvider).isLoading, isTrue);
    expect(container.read(followedTeamIdsProvider).hasError, isFalse);
    expect(container.read(followedTeamIdsProvider).asData, isNull);
    final session = container.read(followSessionProvider);
    expect(session.userId, isNull);
    expect(session.followedIds, isNull);
    expect(session.signedOut, isFalse);
  });

  test('settleFollowList turns a profile AsyncError into a failure', () {
    final decision = settleFollowList(
      sampleSession: false,
      session: const AsyncData('uid'),
      profile: AsyncError<UserProfile?>(
        StateError('permission-denied'),
        StackTrace.empty,
      ),
    );

    expect(decision, isA<FollowListFailed>());
    expect((decision as FollowListFailed).error, isA<StateError>());
  });

  test(
    'followInteractionFrom does not treat a profile AsyncError as signed-out',
    () {
      final interaction = followInteractionFrom(
        sampleSession: false,
        session: const AsyncData('uid'),
        profile: AsyncError<UserProfile?>(
          StateError('permission-denied'),
          StackTrace.empty,
        ),
      );

      expect(interaction.profileFailed, isTrue);
      expect(interaction.userId, isNull);
      expect(interaction.followedIds, isNull);
      expect(interaction.signedOut, isFalse);
    },
  );

  test('accountGate turns a profile AsyncError into a failed gate', () {
    final gate = accountGate(
      sampleSession: false,
      session: const AsyncData('uid'),
      profile: AsyncError<UserProfile?>(
        StateError('permission-denied'),
        StackTrace.empty,
      ),
    );

    expect(gate.kind, AccountGateKind.failed);
    expect(gate.error, isA<StateError>());
  });

  test('a profile read error is not an empty follow list', () async {
    final container = _signedIn(
      Stream<UserProfile?>.error(StateError('permission-denied')),
    );
    addTearDown(container.dispose);
    _keep(container);

    await expectLater(
      container.read(userProfileProvider.future),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      container.read(followedTeamIdsProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(container.read(followedTeamIdsProvider).asData, isNull);
  });

  test('sample session uses the sample uid and production does not', () {
    expect(
      followActorId(
        sampleSession: true,
        firebaseUid: null,
        profileReady: true,
        profileUid: SampleUserRepository.sampleUid,
      ),
      SampleUserRepository.sampleUid,
    );
    expect(
      followActorId(
        sampleSession: false,
        firebaseUid: null,
        profileReady: true,
        profileUid: 'leftover',
      ),
      isNull,
    );
    expect(
      followActorId(
        sampleSession: false,
        firebaseUid: 'firebase-uid',
        profileReady: true,
        profileUid: 'leftover',
      ),
      isNull,
    );
    expect(
      followActorId(
        sampleSession: false,
        firebaseUid: 'firebase-uid',
        profileReady: true,
        profileUid: 'firebase-uid',
      ),
      'firebase-uid',
    );
    expect(
      followActorId(
        sampleSession: false,
        firebaseUid: 'firebase-uid',
        profileReady: false,
        profileUid: 'firebase-uid',
      ),
      isNull,
    );
    expect(
      followActorId(
        sampleSession: true,
        firebaseUid: null,
        profileReady: false,
        profileUid: SampleUserRepository.sampleUid,
      ),
      isNull,
    );
  });

  test('sample profile stream is selected by the sample uid', () async {
    final seen = <String>[];
    final profile = const UserProfile(
      uid: SampleUserRepository.sampleUid,
      email: 'sample@example.com',
      followedTeamIds: ['kashima_antlers'],
    );
    final stream = profileStreamForSession(
      session: const AsyncData(SampleUserRepository.sampleUid),
      watchProfile: (uid) {
        seen.add(uid);
        return Stream<UserProfile?>.value(profile);
      },
    );

    expect(await stream.first, profile);
    expect(seen, [SampleUserRepository.sampleUid]);

    var watched = false;
    final signedOut = profileStreamForSession(
      session: const AsyncData<String?>(null),
      watchProfile: (uid) {
        watched = true;
        return Stream<UserProfile?>.value(profile);
      },
    );
    expect(await signedOut.first, isNull);
    expect(watched, isFalse);
  });

  test('a previous profile is not authority for the next uid', () {
    final profileA = UserProfile(
      uid: 'A',
      email: 'a@example.com',
      followedTeamIds: const ['team-a'],
    );
    final profileB = UserProfile(
      uid: 'B',
      email: 'b@example.com',
      followedTeamIds: const ['team-b'],
    );
    final reloadingB = const AsyncLoading<UserProfile?>().copyWithPrevious(
      AsyncData(profileA),
    );

    final toB = followInteractionFrom(
      sampleSession: false,
      session: const AsyncData('B'),
      profile: reloadingB,
    );
    expect(toB.userId, isNull);
    expect(toB.followedIds, isNull);
    expect(toB.signedOut, isFalse);
    expect(toB.profileFailed, isFalse);

    final signedOut = followInteractionFrom(
      sampleSession: false,
      session: const AsyncData<String?>(null),
      profile: reloadingB,
    );
    expect(signedOut.userId, isNull);
    expect(signedOut.followedIds, isNull);
    expect(signedOut.signedOut, isFalse);

    final fromSignedOut = followInteractionFrom(
      sampleSession: false,
      session: const AsyncData('B'),
      profile: const AsyncLoading<UserProfile?>().copyWithPrevious(
        AsyncData<UserProfile?>(null),
      ),
    );
    expect(fromSignedOut.userId, isNull);
    expect(fromSignedOut.followedIds, isNull);
    expect(fromSignedOut.signedOut, isFalse);

    final authLoading = followInteractionFrom(
      sampleSession: false,
      session: const AsyncLoading<String?>().copyWithPrevious(
        const AsyncData('A'),
      ),
      profile: AsyncData(profileA),
    );
    expect(authLoading.userId, isNull);
    expect(authLoading.followedIds, isNull);

    final authError = followInteractionFrom(
      sampleSession: false,
      session: AsyncError<String?>(
        StateError('permission-denied'),
        StackTrace.empty,
      ).copyWithPrevious(const AsyncData('A')),
      profile: AsyncData(profileA),
    );
    expect(authError.userId, isNull);
    expect(authError.followedIds, isNull);
    expect(authError.profileFailed, isTrue);
    expect(authError.signedOut, isFalse);

    final readyB = followInteractionFrom(
      sampleSession: false,
      session: const AsyncData('B'),
      profile: AsyncData(profileB),
    );
    expect(readyB.userId, 'B');
    expect(readyB.followedIds, ['team-b']);
    expect(readyB.signedOut, isFalse);
  });

  test('user A then user B does not publish A follows while B loads', () async {
    final profiles = <String, StreamController<UserProfile?>>{};
    addTearDown(() async {
      for (final controller in profiles.values) {
        await controller.close();
      }
    });
    final session = StateProvider<AsyncValue<String?>>(
      (ref) => const AsyncData('A'),
    );
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith((ref) => ref.watch(session)),
        userRepositoryProvider.overrideWithValue(
          _ScriptedUsers((uid) {
            return profiles
                .putIfAbsent(uid, StreamController<UserProfile?>.broadcast)
                .stream;
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(userProfileProvider, (_, _) {});
    container.listen(followedTeamIdsProvider, (_, _) {});
    container.listen(followSessionProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    profiles['A']!.add(
      UserProfile(
        uid: 'A',
        email: 'a@example.com',
        followedTeamIds: const ['team-a'],
      ),
    );
    expect((await container.read(userProfileProvider.future))?.uid, 'A');
    expect(await container.read(followedTeamIdsProvider.future), ['team-a']);
    expect(container.read(followSessionProvider).userId, 'A');

    container.read(session.notifier).state = const AsyncData('B');
    await Future<void>.delayed(Duration.zero);
    final mid = container.read(followSessionProvider);
    expect(mid.userId, isNull);
    expect(mid.followedIds, isNull);
    expect(mid.signedOut, isFalse);
    expect(mid.profileFailed, isFalse);
    expect(container.read(followedTeamIdsProvider).isLoading, isTrue);

    profiles['B']!.add(
      UserProfile(
        uid: 'B',
        email: 'b@example.com',
        followedTeamIds: const ['team-b'],
      ),
    );
    expect((await container.read(userProfileProvider.future))?.uid, 'B');
    expect(await container.read(followedTeamIdsProvider.future), ['team-b']);
    expect(container.read(followSessionProvider).userId, 'B');
    expect(container.read(followSessionProvider).followedIds, ['team-b']);
  });
}

void _keep(ProviderContainer container) {
  container.listen(userProfileProvider, (_, _) {});
  container.listen(followedTeamIdsProvider, (_, _) {});
}

ProviderContainer _signedIn(Stream<UserProfile?> profiles) {
  return ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith((ref) => const AsyncData('uid')),
      userRepositoryProvider.overrideWithValue(
        _ScriptedUsers((uid) {
          expect(uid, 'uid');
          return profiles;
        }),
      ),
    ],
  );
}

class _ScriptedUsers implements UserRepository {
  _ScriptedUsers(this._profiles);

  final Stream<UserProfile?> Function(String uid) _profiles;
  final watched = <String>[];

  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    watched.add(uid);
    return _profiles(uid);
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async => null;

  @override
  Future<void> upsertProfile(UserProfile profile) async {}

  @override
  Future<UserProfile> createProfileFromFirebaseUser(User user) {
    throw UnimplementedError();
  }

  @override
  Future<void> followTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {}

  @override
  Future<void> unfollowTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {}

  @override
  Future<void> signOut() async {}
}
