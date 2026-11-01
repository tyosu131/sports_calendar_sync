import '../models/game.dart';
import '../../core/config/app_strings.dart';

enum GameStatusColorRole { live, finished, postponed, cancelled }

class GameStatusPresentation {
  const GameStatusPresentation(this.label, this.colorRole);

  final String label;
  final GameStatusColorRole colorRole;

  static GameStatusPresentation? forStatus(GameStatus status) =>
      switch (status) {
        GameStatus.scheduled => null,
        GameStatus.live => const GameStatusPresentation(
          'LIVE',
          GameStatusColorRole.live,
        ),
        GameStatus.finished => GameStatusPresentation(
          tr('終了'),
          GameStatusColorRole.finished,
        ),
        GameStatus.postponed => GameStatusPresentation(
          tr('延期'),
          GameStatusColorRole.postponed,
        ),
        GameStatus.cancelled => GameStatusPresentation(
          tr('中止'),
          GameStatusColorRole.cancelled,
        ),
      };
}

enum ScoreFormat { normal, compact }

String? formatScore(
  int? home,
  int? away, {
  ScoreFormat format = ScoreFormat.normal,
}) {
  if (home == null || away == null) return null;
  final separator = format == ScoreFormat.normal ? ' - ' : '-';
  return '$home$separator$away';
}

/// Blank values are hidden, while a non-blank venue is returned verbatim.
String? visibleVenue(String? venue) =>
    venue == null || venue.trim().isEmpty ? null : venue;
