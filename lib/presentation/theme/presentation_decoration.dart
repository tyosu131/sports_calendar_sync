import 'package:flutter/material.dart';

/// Decorative fills for browse cards. These are **not** official kit colors.
///
/// Reviewed team colors are not stored in the current model. When
/// `presentationColor` (or equivalent) is added to reviewed presentation
/// data, team cards should prefer that over [decorativeCardFill].
const decorativeCardPalette = <Color>[
  Color(0xFF0D47A1),
  Color(0xFFB71C1C),
  Color(0xFF1B5E20),
  Color(0xFF4A148C),
  Color(0xFFBF360C),
  Color(0xFF006064),
  Color(0xFF880E4F),
  Color(0xFF1A237E),
];

int _stableHash(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 33 + unit) & 0x7fffffff;
  }
  return hash;
}

/// Neutral decorative fill keyed by an arbitrary stable id (for example team
/// id). Same id always maps to the same palette entry.
Color decorativeCardFill(String stableKey) {
  return decorativeCardPalette[_stableHash(stableKey) %
      decorativeCardPalette.length];
}

/// Accent for competition rows and monograms. Uses the competition registry
/// key, not a national flag or club kit.
Color competitionBrowseAccent(String competitionKey) {
  return decorativeCardFill('competition:$competitionKey');
}

/// Future hook: return a reviewed presentation color when the catalog adds one.
Color? reviewedTeamPresentationFill(String teamId) => null;

/// Card background: reviewed color when available, otherwise decorative fill.
Color teamBrowseCardFill(String teamId) {
  return reviewedTeamPresentationFill(teamId) ?? decorativeCardFill(teamId);
}
