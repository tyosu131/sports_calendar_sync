import '../../domain/models/game.dart';

/// Builds a local, copyable iCalendar document for Free MVP flows.
///
/// This is intentionally local-only: it does not publish a URL, call Cloud
/// Functions, or write any backend state.  DTEND is omitted because game
/// durations differ across sports and the current Free MVP data model does not
/// carry an authoritative end time.
class LocalIcsBuilder {
  const LocalIcsBuilder._();

  static const _uidDomain = 'sports-calendar-sync.local';
  static const _prodId = '-//sports_calendar_sync//Free MVP Local ICS//EN';

  static String buildForTeam({
    required String teamId,
    required Iterable<Game> games,
    DateTime? generatedAtUtc,
  }) {
    final dtStamp = _formatUtc(generatedAtUtc ?? DateTime.now().toUtc());
    final sortedGames = games.toList()
      ..sort(
        (a, b) => a.startTimeUtcDateTime.compareTo(b.startTimeUtcDateTime),
      );

    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:$_prodId',
      'CALSCALE:GREGORIAN',
      'X-WR-CALNAME:${_escapeText('sports_calendar_sync $teamId')}',
      'X-WR-TIMEZONE:Asia/Tokyo',
      for (final game in sortedGames) ..._eventLines(game, dtStamp),
      'END:VCALENDAR',
    ];

    return '${lines.join('\r\n')}\r\n';
  }

  static List<String> _eventLines(Game game, String dtStamp) {
    return [
      'BEGIN:VEVENT',
      'UID:${_escapeText('${game.id}@$_uidDomain')}',
      'DTSTAMP:$dtStamp',
      'DTSTART:${_formatUtc(game.startTimeUtcDateTime)}',
      'SUMMARY:${_escapeText(_summaryFor(game))}',
      'DESCRIPTION:${_escapeText(_descriptionFor(game))}',
      'LOCATION:${_escapeText(game.venue ?? '')}',
      'END:VEVENT',
    ];
  }

  static String _summaryFor(Game game) {
    return '${game.homeTeamNameJa} vs ${game.awayTeamNameJa}';
  }

  static String _descriptionFor(Game game) {
    final lines = <String>[
      'sports_calendar_sync Free MVP local ICS',
      'Status: ${_statusLabel(game.status)}',
      if (_scoreFor(game) != null) 'Score: ${_scoreFor(game)}',
      if (game.competitionKey != null) 'Competition: ${game.competitionKey}',
      if (game.competitionSeasonKey != null)
        'Competition season: ${game.competitionSeasonKey}',
      'Source: local sample-mode generation',
    ];

    return lines.join('\n');
  }

  static String _statusLabel(GameStatus status) {
    return switch (status) {
      GameStatus.scheduled => 'scheduled',
      GameStatus.live => 'live',
      GameStatus.finished => 'finished',
      GameStatus.postponed => 'postponed',
      GameStatus.cancelled => 'cancelled',
    };
  }

  static String? _scoreFor(Game game) {
    final homeScore = game.homeScore;
    final awayScore = game.awayScore;
    if (homeScore == null || awayScore == null) {
      return null;
    }
    return '$homeScore - $awayScore';
  }

  static String _formatUtc(DateTime value) {
    final utc = value.toUtc();
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${utc.year.toString().padLeft(4, '0')}'
        '${twoDigits(utc.month)}'
        '${twoDigits(utc.day)}T'
        '${twoDigits(utc.hour)}'
        '${twoDigits(utc.minute)}'
        '${twoDigits(utc.second)}Z';
  }

  static String _escapeText(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(r'\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }
}
