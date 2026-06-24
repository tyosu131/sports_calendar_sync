import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/game_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/user_repository.dart';

// ── Repository providers ──────────────────────────────────────────────────────

const useSampleData = bool.fromEnvironment('USE_SAMPLE_DATA');

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return useSampleData ? SampleUserRepository() : FirestoreUserRepository();
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return useSampleData ? SampleTeamRepository() : FirestoreTeamRepository();
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return useSampleData ? SampleGameRepository() : FirestoreGameRepository();
});
