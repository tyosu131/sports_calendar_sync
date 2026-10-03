import 'dart:math' as math;

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

/// Team-name color for one side panel.
///
/// The background is the painted fill, not the palette entry. White and
/// black are compared with the WCAG contrast ratio, and the higher one
/// is used. Home and away are chosen independently.
Color competitionVsFrameTextColor(Color base) {
  final background = competitionVsFrameFill(base);
  final onWhite = contrastRatio(Colors.white, background);
  final onBlack = contrastRatio(Colors.black, background);
  return onWhite >= onBlack ? Colors.white : Colors.black;
}

/// WCAG 2 contrast ratio. Channels are the sRGB values in 0–1.
double contrastRatio(Color foreground, Color background) {
  final lighter = math.max(
    relativeLuminance(foreground),
    relativeLuminance(background),
  );
  final darker = math.min(
    relativeLuminance(foreground),
    relativeLuminance(background),
  );
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG 2 relative luminance for an sRGB color.
double relativeLuminance(Color color) {
  final red = _srgbChannelToLinear(color.r);
  final green = _srgbChannelToLinear(color.g);
  final blue = _srgbChannelToLinear(color.b);
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}

double _srgbChannelToLinear(double channel) {
  if (channel <= 0.04045) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}
