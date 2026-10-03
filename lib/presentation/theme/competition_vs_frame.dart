import 'package:flutter/material.dart';

import 'presentation_decoration.dart';

/// Decorative home/away frame colors for one competition.
///
/// These are palette entries keyed by the competition, not club kit colors.
/// Home and away are always different colors. The same competition always
/// yields the same pair, regardless of team names.
class CompetitionVsFrameColors {
  const CompetitionVsFrameColors({required this.home, required this.away});

  final Color home;
  final Color away;
}

/// Home is a grounded rounded panel. Away is a chevron-ended panel.
/// The shapes differ so color is not the only side signal.
enum CompetitionVsSideKind { home, away }

CompetitionVsFrameColors competitionVsFrameColors(String? competitionKey) {
  final trimmed = competitionKey?.trim();
  final stable = (trimmed == null || trimmed.isEmpty) ? 'unknown' : trimmed;
  final home = decorativeCardFill('vs-home:$stable');
  final homeIndex = decorativeCardPalette.indexOf(home);
  if (homeIndex < 0) {
    return CompetitionVsFrameColors(
      home: decorativeCardPalette[0],
      away: decorativeCardPalette[1],
    );
  }
  var awayIndex = decorativeCardPalette.indexOf(
    decorativeCardFill('vs-away:$stable'),
  );
  if (awayIndex < 0 || awayIndex == homeIndex) {
    awayIndex = (homeIndex + 3) % decorativeCardPalette.length;
  }
  return CompetitionVsFrameColors(
    home: decorativeCardPalette[homeIndex],
    away: decorativeCardPalette[awayIndex],
  );
}

/// Fill painted inside a side frame. Still the competition color, lifted
/// enough to separate it from the dark card surface.
Color competitionVsFrameFill(Color base) =>
    Color.lerp(base, Colors.white, 0.22)!;

/// Stroke and side mark. Lighter than the fill so the shape reads on it.
Color competitionVsFrameInk(Color base) =>
    Color.lerp(base, Colors.white, 0.72)!;
