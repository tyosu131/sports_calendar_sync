import 'package:flutter/material.dart';

import 'presentation_decoration.dart';

/// Deprecated name kept for tests. Prefer [decorativeCardFill] /
/// [competitionBrowseAccent].
const leagueBrowseAccents = decorativeCardPalette;

Color leagueBrowseAccent(String key) => decorativeCardFill(key);
