import 'package:flutter/foundation.dart';

/// Name language chosen in Settings (stored as the profile's
/// `preferredLanguage`).
///
/// [auto] (`ja`): Japanese teams, people, venues and competitions use
/// Japanese. Everything from abroad uses English.
/// [english] (`en`): every team, person, venue and competition name uses
/// English.
///
/// Only names follow this setting. App chrome (buttons, tabs, messages) is
/// still Japanese.
enum DisplayLanguageMode { auto, english }

/// App-wide current mode. Name policies read it at call time; the app root
/// rebuilds its route tree when it changes.
final ValueNotifier<DisplayLanguageMode> displayLanguageMode =
    ValueNotifier<DisplayLanguageMode>(DisplayLanguageMode.auto);

bool get displayLanguageForcesEnglish =>
    displayLanguageMode.value == DisplayLanguageMode.english;

/// Maps the stored profile value. Anything other than `en` is auto.
DisplayLanguageMode displayLanguageModeFor(String? preferredLanguage) =>
    preferredLanguage == 'en'
    ? DisplayLanguageMode.english
    : DisplayLanguageMode.auto;
