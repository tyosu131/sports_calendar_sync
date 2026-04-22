import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/user_profile.dart';

/// Handles all Firestore operations for user profiles.
class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  /// Returns the currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Fetch user profile from Firestore. Returns null if not found.
  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!, uid);
  }

  /// Stream of user profile changes (real-time).
  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromFirestore(snap.data()!, uid);
    });
  }

  /// Create or update user profile in Firestore.
  Future<void> upsertProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Create a new profile on first sign-in.
  Future<UserProfile> createProfileFromFirebaseUser(User user) async {
    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: Timestamp.now(),
    );
    await upsertProfile(profile);
    return profile;
  }

  /// Add a team to the user's followed list.
  Future<void> followTeam(String uid, String teamId) async {
    await _users.doc(uid).update({
      'followedTeamIds': FieldValue.arrayUnion([teamId]),
    });
  }

  /// Remove a team from the user's followed list.
  Future<void> unfollowTeam(String uid, String teamId) async {
    await _users.doc(uid).update({
      'followedTeamIds': FieldValue.arrayRemove([teamId]),
    });
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
