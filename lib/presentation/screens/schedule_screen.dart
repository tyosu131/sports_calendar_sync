import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_time_utils.dart';
import '../../data/providers/game_providers.dart';
import '../../domain/models/game.dart';

/// In-app schedule view for followed-team games.
///
/// This screen is intentionally competition-agnostic: any [Game] returned by
/// [scheduleGamesForFollowedTeamsProvider] can be grouped and displayed here.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime? _visibleMonth;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(scheduleGamesForFollowedTeamsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('スケジュール')),
      body: gamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (games) {
          if (games.isEmpty) {
            return const _ScheduleEmptyState();
          }

          final gamesByDate = _groupGamesByJstDate(games);
          final visibleMonth =
              _visibleMonth ?? _initialVisibleMonth(gamesByDate);
          final selectedDate = _selectedDate;
          final selectedGames = selectedDate == null
              ? const <Game>[]
              : gamesByDate[selectedDate] ?? const <Game>[];

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _MonthSchedulePicker(
                        visibleMonth: visibleMonth,
                        minMonth: _minMonth(gamesByDate.keys),
                        maxMonth: _maxMonth(gamesByDate.keys),
                        selectedDate: selectedDate,
                        gamesByDate: gamesByDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                            _visibleMonth = DateTime(date.year, date.month);
                          });
                        },
                        onMonthChanged: (month) {
                          setState(() => _visibleMonth = month);
                        },
                      ),
                      if (selectedDate == null)
                        const _SelectDateHint()
                      else
                        _SelectedDateDetails(
                          selectedDate: selectedDate,
                          games: selectedGames,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime _initialVisibleMonth(Map<DateTime, List<Game>> gamesByDate) {
    final sortedDates = gamesByDate.keys.toList()..sort();
    final firstDate = sortedDates.first;
    return DateTime(firstDate.year, firstDate.month);
  }

  Map<DateTime, List<Game>> _groupGamesByJstDate(List<Game> games) {
    final sortedGames = [...games]
      ..sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));

    final grouped = <DateTime, List<Game>>{};
    for (final game in sortedGames) {
      final jst = DateTimeUtils.toJst(game.startTimeUtcDateTime);
      final dateKey = DateTime(jst.year, jst.month, jst.day);
      grouped.putIfAbsent(dateKey, () => []).add(game);
    }
    return grouped;
  }

  DateTime _minMonth(Iterable<DateTime> dates) {
    final sorted = dates.toList()..sort();
    return DateTime(sorted.first.year, sorted.first.month);
  }

  DateTime _maxMonth(Iterable<DateTime> dates) {
    final sorted = dates.toList()..sort();
    return DateTime(sorted.last.year, sorted.last.month);
  }
}

class _MonthSchedulePicker extends StatelessWidget {
  const _MonthSchedulePicker({
    required this.visibleMonth,
    required this.minMonth,
    required this.maxMonth,
    required this.selectedDate,
    required this.gamesByDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  final DateTime visibleMonth;
  final DateTime minMonth;
  final DateTime maxMonth;
  final DateTime? selectedDate;
  final Map<DateTime, List<Game>> gamesByDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;

  static const _maxCalendarWidth = 1160.0;

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = visibleMonth.isAfter(minMonth);
    final canGoNext = visibleMonth.isBefore(maxMonth);
    final days = _monthCells(visibleMonth);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxCalendarWidth),
        child: Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '前の月',
                      visualDensity: VisualDensity.compact,
                      onPressed: canGoPrevious
                          ? () => onMonthChanged(
                              DateTime(
                                visibleMonth.year,
                                visibleMonth.month - 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${visibleMonth.year}年${visibleMonth.month}月',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: '次の月',
                      visualDensity: VisualDensity.compact,
                      onPressed: canGoNext
                          ? () => onMonthChanged(
                              DateTime(
                                visibleMonth.year,
                                visibleMonth.month + 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const _WeekdayHeader(),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    mainAxisExtent: 112,
                  ),
                  itemBuilder: (context, index) {
                    final date = days[index];
                    if (date == null) return const SizedBox.shrink();

                    return _DateCell(
                      date: date,
                      selectedDate: selectedDate,
                      games: gamesByDate[date] ?? const <Game>[],
                      onTap: () => onDateSelected(date),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime?> _monthCells(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7; // Sunday starts at 0.

    return [
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ];
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: Center(
              child: Text(
                weekday,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
      ],
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.selectedDate,
    required this.games,
    required this.onTap,
  });

  final DateTime date;
  final DateTime? selectedDate;
  final List<Game> games;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todayJst = DateTimeUtils.toJst(DateTime.now().toUtc());
    final today = DateTime(todayJst.year, todayJst.month, todayJst.day);
    final isSelected = selectedDate != null && _isSameDate(date, selectedDate!);
    final isToday = _isSameDate(date, today);
    final isPast = date.isBefore(today);

    final backgroundColor = isSelected
        ? colorScheme.primary
        : isToday
        ? colorScheme.primaryContainer
        : Colors.transparent;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : isPast
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;
    final hasGame = games.isNotEmpty;
    final firstGame = games.isEmpty ? null : games.first;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected || isToday
                ? colorScheme.primary
                : hasGame
                    ? colorScheme.outlineVariant.withValues(alpha: 0.55)
                    : colorScheme.outlineVariant.withValues(alpha: 0.28),
            width: isSelected || isToday ? 1.2 : 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : null,
                    ),
                  ),
                  const Spacer(),
                  if (games.length > 1)
                    Text(
                      '+${games.length - 1}',
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (firstGame != null) ...[
                const SizedBox(height: 2),
                Expanded(
                  child: _CalendarGamePreview(
                    game: firstGame,
                    foregroundColor: foregroundColor,
                    selected: isSelected,
                  ),
                ),
              ] else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CalendarGamePreview extends StatelessWidget {
  const _CalendarGamePreview({
    required this.game,
    required this.foregroundColor,
    required this.selected,
  });

  final Game game;
  final Color foregroundColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final meta = _calendarMeta(game);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 112,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniTeamIcon(
                  name: game.homeTeamNameJa,
                  logoUrl: game.homeTeamLogoUrl,
                  foregroundColor: foregroundColor,
                  selected: selected,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _MiniTeamIcon(
                  name: game.awayTeamNameJa,
                  logoUrl: game.awayTeamLogoUrl,
                  foregroundColor: foregroundColor,
                  selected: selected,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calendarMeta(Game game) {
    final score = _scoreText(game);
    switch (game.status) {
      case GameStatus.scheduled:
        return DateTimeUtils.formatTimeOnly(game.startTimeUtcDateTime);
      case GameStatus.live:
        return score == null ? 'LIVE' : '$score LIVE';
      case GameStatus.finished:
        return score == null ? '終了' : '$score 終了';
      case GameStatus.postponed:
        return '延期';
      case GameStatus.cancelled:
        return '中止';
    }
  }

  String? _scoreText(Game game) {
    final homeScore = game.homeScore;
    final awayScore = game.awayScore;
    if (homeScore == null || awayScore == null) return null;
    return '$homeScore - $awayScore';
  }
}

class _MiniTeamIcon extends StatelessWidget {
  const _MiniTeamIcon({
    required this.name,
    required this.logoUrl,
    required this.foregroundColor,
    required this.selected,
  });

  final String name;
  final String? logoUrl;
  final Color foregroundColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      name.isEmpty ? '?' : String.fromCharCode(name.runes.first),
      style: TextStyle(
        color: foregroundColor,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );

    return CircleAvatar(
      radius: 11,
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: logoUrl == null || logoUrl!.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                logoUrl!,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: foregroundColor,
                ),
              ),
            ),
    );
  }
}

class ScheduleGameTile extends StatelessWidget {
  const ScheduleGameTile({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = _statusText(game);
    final scoreText = _scoreOrVs(game);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateTimeUtils.formatTimeOnly(game.startTimeUtcDateTime),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (statusText != null)
                  _StatusChip(statusText: statusText, status: game.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TeamSide(
                    name: game.homeTeamNameJa,
                    logoUrl: game.homeTeamLogoUrl,
                    alignment: CrossAxisAlignment.start,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    scoreText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _TeamSide(
                    name: game.awayTeamNameJa,
                    logoUrl: game.awayTeamLogoUrl,
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            if (game.venue != null && game.venue!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game.venue!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _scoreOrVs(Game game) {
    if (game.status == GameStatus.live || game.status == GameStatus.finished) {
      final homeScore = game.homeScore;
      final awayScore = game.awayScore;
      if (homeScore != null && awayScore != null) {
        return '$homeScore - $awayScore';
      }
    }
    return 'vs';
  }

  String? _statusText(Game game) {
    switch (game.status) {
      case GameStatus.scheduled:
        return null;
      case GameStatus.live:
        return 'LIVE';
      case GameStatus.finished:
        return '終了';
      case GameStatus.postponed:
        return '延期';
      case GameStatus.cancelled:
        return '中止';
    }
  }
}

class _SelectDateHint extends StatelessWidget {
  const _SelectDateHint();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Text(
        '日付を選択すると試合詳細を表示します',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _SelectedDateDetails extends StatelessWidget {
  const _SelectedDateDetails({required this.selectedDate, required this.games});

  final DateTime selectedDate;
  final List<Game> games;

  @override
  Widget build(BuildContext context) {
    final title = '${_formatSelectedDate(selectedDate)}の試合';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (games.isEmpty)
          const _SelectedDateEmptyState()
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                for (final game in games) ScheduleGameTile(game: game),
              ],
            ),
          ),
      ],
    );
  }

  String _formatSelectedDate(DateTime date) {
    final utcForJstMidnight = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).subtract(const Duration(hours: 9));
    return DateTimeUtils.formatDateOnly(utcForJstMidnight);
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.name,
    required this.logoUrl,
    required this.alignment,
  });

  final String name;
  final String? logoUrl;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        _TeamIcon(name: name, logoUrl: logoUrl),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TeamIcon extends StatelessWidget {
  const _TeamIcon({required this.name, required this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      name.isEmpty ? '?' : String.fromCharCode(name.runes.first),
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: logoUrl == null || logoUrl!.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                logoUrl!,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shield_outlined, size: 18),
              ),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.statusText, required this.status});

  final String statusText;
  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      GameStatus.live => colorScheme.error,
      GameStatus.finished => colorScheme.secondary,
      GameStatus.postponed || GameStatus.cancelled => colorScheme.tertiary,
      GameStatus.scheduled => colorScheme.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 80,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '表示できる試合がありません',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'フォロー中チームの試合があると、ここに日付別で表示されます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDateEmptyState extends StatelessWidget {
  const _SelectedDateEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(child: Text('この日の試合はありません')),
    );
  }
}
