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

  test('a missing profile is empty follows, not an error', () async {
    final container = _signedIn(Stream<UserProfile?>.value(null));
    addTearDown(container.dispose);
    _keep(container);

    expect(await container.read(userProfileProvider.future), isNull);
    expect(await container.read(followedTeamIdsProvider.future), isEmpty);
    expect(container.read(userProfileProvider).hasError, isFalse);
    expect(container.read(followedTeamIdsProvider).hasError, isFalse);
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
        profileSettled: true,
        profileUid: SampleUserRepository.sampleUid,
      ),
      SampleUserRepository.sampleUid,
    );
    expect(
      followActorId(
        sampleSession: false,
        firebaseUid: null,
        profileSettled: true,
        profileUid: 'leftover',
      ),
      isNull,
    );
    expect(
      followActorId(
        sampleSession: false,
        firebaseUid: 'firebase-uid',
        profileSettled: true,
        profileUid: 'leftover',
      ),
      'firebase-uid',
    );
    expect(
      followActorId(
        sampleSession: true,
        firebaseUid: null,
        profileSettled: false,
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
