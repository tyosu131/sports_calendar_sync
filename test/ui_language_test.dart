import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/core/config/app_strings.dart';
import 'package:sports_calendar_sync/core/config/display_language_setting.dart';
import 'package:sports_calendar_sync/core/utils/date_time_utils.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/policies/game_presentation_policy.dart';
import 'package:sports_calendar_sync/domain/policies/home_sport_navigation.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
    await initializeDateFormatting('en');
  });
  tearDown(() => displayLanguageMode.value = DisplayLanguageMode.auto);

  test('every tr() text in lib has an English translation', () {
    final literal = RegExp(r'''tr(?:Args)?\(\s*(['"])((?:(?!\1).)+)\1''');
    displayLanguageMode.value = DisplayLanguageMode.english;
    final missing = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('app_strings.dart')) continue;
      for (final match in literal.allMatches(entity.readAsStringSync())) {
        final text = match.group(2)!;
        if (!RegExp(r'[぀-ヿ一-鿿]').hasMatch(text)) continue;
        if (tr(text) == text) missing.add('${entity.path}: $text');
      }
    }
    expect(missing, isEmpty);
  });

  test('Japanese is the default and English switches text, tabs and dates', () {
    expect(tr('設定'), '設定');
    expect(homeSportTabs().map((tab) => tab.label), contains('サッカー'));
    expect(GameStatusPresentation.forStatus(GameStatus.finished)?.label, '終了');
    final date = DateTime.utc(2026, 11, 8, 10);
    expect(DateTimeUtils.formatJstDate(date), '2026年11月8日(日)');

    displayLanguageMode.value = DisplayLanguageMode.english;
    expect(tr('設定'), 'Settings');
    expect(trArgs('{n}試合', {'n': '3'}), '3 games');
    expect(
      homeSportTabs().map((tab) => tab.label),
      ['Favorites', 'Baseball', 'Soccer', 'Basketball', 'American Football', 'Hockey', 'MMA'],
    );
    expect(GameStatusPresentation.forStatus(GameStatus.finished)?.label, 'Final');
    expect(DateTimeUtils.formatJstDate(date), 'Nov 8, 2026');
    expect(tr('この文は辞書にない'), 'この文は辞書にない');
  });
}
