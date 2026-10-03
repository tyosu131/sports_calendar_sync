import 'package:flutter/material.dart';

/// Eight dark, distinct fills. These are not kit colors.
///
/// No team or competition color is stored in the current model. The same id
/// always maps to the same entry so a card does not change between visits.
const leagueBrowseAccents = <Color>[
  Color(0xFF0D47A1),
  Color(0xFFB71C1C),
  Color(0xFF1B5E20),
  Color(0xFF4A148C),
  Color(0xFFBF360C),
  Color(0xFF006064),
  Color(0xFF880E4F),
  Color(0xFF1A237E),
];

/// Stable non-gray accent for [key]. Not an official club or competition color.
Color leagueBrowseAccent(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 33 + unit) & 0x7fffffff;
  }
  return leagueBrowseAccents[hash % leagueBrowseAccents.length];
}
