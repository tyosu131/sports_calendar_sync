import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/repository_providers.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';
import 'package:sports_calendar_sync/presentation/widgets/follow_toggle.dart';

void main() {
  testWidgets('follow and unfollow succeed without a snackbar', (tester) async {
    final repository = _RecordingUsers();
    await _pump(
      tester,
      repository: repository,
      session: const FollowInteraction(
        userId: 'uid',
        followedIds: ['arsenal'],
        profileFailed: false,
        signedOut: false,
      ),
      teamId: 'arsenal',
    );

    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(repository.unfollowed, ['arsenal']);
    expect(find.text('フォローを更新できませんでした'), findsNothing);
    expect(find.text('sign-in-page'), findsNothing);

    repository.unfollowed.clear();
    await _pump(
      tester,
      repository: repository,
      session: const FollowInteraction(
        userId: 'uid',
        followedIds: [],
        profileFailed: false,
        signedOut: false,
      ),
      teamId: 'kashima_antlers',
    );
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(repository.followed, ['kashima_antlers']);
    expect(find.text('フォローを更新できませんでした'), findsNothing);
  });

  testWidgets('follow and unfollow exceptions stay on the button', (
    tester,
  ) async {
    final repository = _RecordingUsers(error: Exception('permission-denied'));
    await _pump(
      tester,
      repository: repository,
      session: const FollowInteraction(
        userId: 'uid',
        followedIds: [],
        profileFailed: false,
        signedOut: false,
      ),
      teamId: 'kashima_antlers',
    );
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(find.text('フォローを更新できませんでした'), findsOneWidget);
    expect(find.text('sign-in-page'), findsNothing);
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      repository: _RecordingUsers(error: Exception('unavailable')),
      session: const FollowInteraction(
        userId: 'uid',
        followedIds: ['kashima_antlers'],
        profileFailed: false,
        signedOut: false,
      ),
      teamId: 'kashima_antlers',
    );
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(find.text('フォローを更新できませんでした'), findsOneWidget);
    expect(find.text('sign-in-page'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a programmer error from follow is not swallowed', (
    tester,
  ) async {
    final repository = _RecordingUsers(error: StateError('bug'));
    late BuildContext buttonContext;
    late WidgetRef buttonRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                buttonContext = context;
                buttonRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    await expectLater(
      toggleFollow(
        buttonContext,
        buttonRef,
        const FollowInteraction(
          userId: 'uid',
          followedIds: [],
          profileFailed: false,
          signedOut: false,
        ),
        'kashima_antlers',
        'football_j1',
      ),
      throwsA(isA<StateError>()),
    );
    expect(find.text('フォローを更新できませんでした'), findsNothing);
  });

  testWidgets('sign-in opens only for a settled signed-out session', (
    tester,
  ) async {
    await _pump(
      tester,
      repository: _RecordingUsers(),
      session: const FollowInteraction(
        userId: null,
        followedIds: [],
        profileFailed: false,
        signedOut: true,
      ),
      teamId: 'kashima_antlers',
    );
    await tester.tap(find.text('toggle'));
    await tester.pumpAndSettle();
    expect(find.text('sign-in-page'), findsOneWidget);

    await _pump(
      tester,
      repository: _RecordingUsers(),
      session: const FollowInteraction(
        userId: null,
        followedIds: null,
        profileFailed: true,
        signedOut: false,
      ),
      teamId: 'kashima_antlers',
    );
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(find.text('フォロー状態を確認できません'), findsOneWidget);
    expect(find.text('sign-in-page'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required UserRepository repository,
  required FollowInteraction session,
  required String teamId,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  toggleFollow(context, ref, session, teamId, 'football_j1'),
              child: const Text('toggle'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/signin', builder: (_, _) => const Text('sign-in-page')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

class _RecordingUsers implements UserRepository {
  _RecordingUsers({this.error});

  final Object? error;
  final followed = <String>[];
  final unfollowed = <String>[];

  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  Future<UserProfile?> fetchProfile(String uid) async => null;

  @override
  Stream<UserProfile?> watchProfile(String uid) => const Stream.empty();

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
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    followed.add(teamId);
  }

  @override
  Future<void> unfollowTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    unfollowed.add(teamId);
  }

  @override
  Future<void> signOut() async {}
}
