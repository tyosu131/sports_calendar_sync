import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/game_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/user_repository.dart';

// ── Repository providers ──────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository();
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});
