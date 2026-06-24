import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_profile.dart';
import '../repositories/user_repository.dart';
import 'repository_providers.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

/// Stream of Firebase auth state (User? — null means signed out)
final authStateProvider = StreamProvider<User?>((ref) {
  if (useSampleData) return Stream<User?>.value(null);
  return ref.watch(userRepositoryProvider).authStateChanges;
});

/// The current Firebase User (throws if not authenticated)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ── User profile ──────────────────────────────────────────────────────────────

/// Stream of the current user's Firestore profile.
/// Returns null if not signed in or profile not yet created.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  if (useSampleData) {
    return ref
        .watch(userRepositoryProvider)
        .watchProfile(SampleUserRepository.sampleUid);
  }

  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchProfile(user.uid);
});

/// Convenience: flat list of all followed team IDs for the current user.
///
/// Uses [UserProfile.allFavoriteTeamIds] which returns the union of all
/// per-competition team IDs when available, falling back to the legacy
/// [UserProfile.followedTeamIds] field for old documents.
final followedTeamIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(userProfileProvider).valueOrNull?.allFavoriteTeamIds ?? [];
});
