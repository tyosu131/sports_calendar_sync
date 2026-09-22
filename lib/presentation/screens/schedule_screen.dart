import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_time_utils.dart';
import '../../data/providers/game_providers.dart';
import '../../domain/models/game.dart';
import '../../domain/policies/competition_display_policy.dart';
import '../../domain/policies/game_presentation_policy.dart';
import '../../domain/policies/team_display_name_policy.dart';
import '../../domain/policies/team_initial.dart';
import '../../domain/policies/team_presentation_policy.dart';
import '../widgets/competition_badge.dart';
import '../widgets/game_presentation_scope.dart';
import '../widgets/game_status_chip.dart';
import '../widgets/team_presentation_badge.dart';

/// In-app schedule view for followed-team games.
///
/// This screen is intentionally competition-agnostic: any [Game] returned by
/// [scheduleGamesForFollowedTeamsProvider] can be grouped and displayed here.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, this.now = DateTime.now});

  final DateTime Function() now;

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
              _visibleMonth ??
              resolveInitialVisibleMonth(
                gamesByDate.keys,
                widget.now().toUtc(),
              );
          final selectedDate = _selectedDate;
          final selectedGames = selectedDate == null
              ? const <Game>[]
              : gamesByDate[selectedDate] ?? const <Game>[];

          final resolver = ref
              .watch(gamePresentationProvider(games))
              .valueOrNull;
          return GamePresentationScope(
            resolver: resolver ?? TeamPresentationLogoResolver(const []),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        ScheduleMonthCalendar(
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
            ),
          );
        },
      ),
    );
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

/// Chooses the current JST month, clamped to the months represented by games.
@visibleForTesting
DateTime resolveInitialVisibleMonth(
  Iterable<DateTime> availableDates,
  DateTime nowUtc,
) {
  final dates = availableDates.toList()..sort();
  final minMonth = DateTime(dates.first.year, dates.first.month);
  final maxMonth = DateTime(dates.last.year, dates.last.month);
  final nowJst = DateTimeUtils.toJst(nowUtc);
  final currentMonth = DateTime(nowJst.year, nowJst.month);
  if (currentMonth.isBefore(minMonth)) return minMonth;
  if (currentMonth.isAfter(maxMonth)) return maxMonth;
  return currentMonth;
}

@visibleForTesting
class ScheduleMonthCalendar extends StatelessWidget {
  const ScheduleMonthCalendar({
    super.key,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxCalendarWidth),
        child: Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${visibleMonth.year}年${visibleMonth.month}月',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'フォロー中チームの試合予定',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
                const SizedBox(height: 8),
                const _WeekdayHeader(),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 700;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: days.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: compact ? 2 : 4,
                        crossAxisSpacing: compact ? 2 : 4,
                        mainAxisExtent: compact ? 88 : 112,
                      ),
                      itemBuilder: (context, index) {
                        final date = days[index];
                        if (date == null) return const SizedBox.shrink();

                        return _DateCell(
                          date: date,
                          selectedDate: selectedDate,
                          games: gamesByDate[date] ?? const <Game>[],
                          compact: compact,
                          onTap: () => onDateSelected(date),
                        );
                      },
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
        for (var index = 0; index < weekdays.length; index++)
          Expanded(
            child: Center(
              child: Text(
                weekdays[index],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: index == 0
                      ? Theme.of(context).colorScheme.error
                      : index == 6
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
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
    required this.compact,
    required this.onTap,
  });

  final DateTime date;
  final DateTime? selectedDate;
  final List<Game> games;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todayJst = DateTimeUtils.toJst(DateTime.now().toUtc());
    final today = DateTime(todayJst.year, todayJst.month, todayJst.day);
    final isSelected = selectedDate != null && _isSameDate(date, selectedDate!);
    final isToday = _isSameDate(date, today);
    final isPast = date.isBefore(today);
    final hasGame = games.isNotEmpty;

    final backgroundColor = isSelected
        ? colorScheme.primary
        : isToday
        ? colorScheme.primaryContainer
        : hasGame
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
        : colorScheme.surface;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : isPast
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected || isToday
                ? colorScheme.primary
                : hasGame
                ? colorScheme.outlineVariant.withValues(alpha: 0.72)
                : colorScheme.outlineVariant.withValues(alpha: 0.28),
            width: isSelected || isToday ? 1.4 : 0.8,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 3 : 5,
            vertical: compact ? 3 : 5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : null,
                    ),
                  ),
                  const Spacer(),
                  if (games.length > 1 && !compact)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.onPrimary.withValues(alpha: 0.18)
                            : colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${games.length}試合',
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (games.isNotEmpty) ...[
                const SizedBox(height: 3),
                Expanded(
                  child: compact
                      ? _CompactCalendarGames(
                          games: games,
                          foregroundColor: foregroundColor,
                        )
                      : _CalendarGamePreview(
                          game: games.first,
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

class _CompactCalendarGames extends StatelessWidget {
  const _CompactCalendarGames({
    required this.games,
    required this.foregroundColor,
  });

  final List<Game> games;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final visible = games.take(2).toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (var index = 0; index < visible.length; index++)
          Expanded(
            child: _CompactGameLine(
              key: ValueKey('compact-game-${visible[index].id}'),
              game: visible[index],
              foregroundColor: foregroundColor,
            ),
          ),
        if (games.length > 2)
          Text(
            '+${games.length - 2}',
            key: const ValueKey('compact-more-games'),
            style: TextStyle(
              color: foregroundColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
      ],
    );
  }
}

class _CompactGameLine extends StatelessWidget {
  const _CompactGameLine({
    super.key,
    required this.game,
    required this.foregroundColor,
  });

  final Game game;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final home = teamDisplayNames.homeName(game);
    final away = teamDisplayNames.awayName(game);
    final marker = '${teamInitial(home)}/${teamInitial(away)}';
    final meta = _compactMeta(game);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          marker,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: foregroundColor, fontSize: 8),
        ),
      ],
    );
  }

  String _compactMeta(Game game) => switch (game.status) {
    GameStatus.scheduled => DateTimeUtils.formatTimeOnly(
      game.startTimeUtcDateTime,
    ),
    GameStatus.live => 'LIVE',
    GameStatus.finished =>
      game.homeScore != null && game.awayScore != null
          ? formatScore(
              game.homeScore,
              game.awayScore,
              format: ScoreFormat.compact,
            )!
          : '終了',
    GameStatus.postponed => '延期',
    GameStatus.cancelled => '中止',
  };
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
        width: 168,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniTeamIcon(
                  name: teamDisplayNames.homeName(game),
                  logoUrl: GamePresentationScope.logo(context, game, true),
                  foregroundColor: foregroundColor,
                  selected: selected,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _MiniTeamIcon(
                  name: teamDisplayNames.awayName(game),
                  logoUrl: GamePresentationScope.logo(context, game, false),
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
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calendarMeta(Game game) {
    final score = formatScore(game.homeScore, game.awayScore);
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
  Widget build(BuildContext context) => TeamPresentationBadge(
        size: 36,
        displayName: name,
        logoUrl: logoUrl,
        foregroundColor: foregroundColor,
        fontSize: 13,
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        imageInset: 2,
      );
}

class ScheduleGameTile extends StatelessWidget {
  const ScheduleGameTile({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreText = _scoreOrVs(game);
    final competition = CompetitionDisplayPolicy.forKey(game.competitionKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (competition != null) ...[
              CompetitionBadge(competition: competition),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Text(
                  DateTimeUtils.formatTimeOnly(game.startTimeUtcDateTime),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GameStatusChip(status: game.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TeamSide(
                    name: teamDisplayNames.homeName(game),
                    logoUrl: GamePresentationScope.logo(context, game, true),
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
                    name: teamDisplayNames.awayName(game),
                    logoUrl: GamePresentationScope.logo(context, game, false),
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            if (visibleVenue(game.venue) case final venue?) ...[
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
                      venue,
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
        return formatScore(homeScore, awayScore)!;
      }
    }
    return 'vs';
  }
}

class _SelectDateHint extends StatelessWidget {
  const _SelectDateHint();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.36,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '日付を選択すると試合詳細を表示します',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
        ),
      ),
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
  Widget build(BuildContext context) => TeamPresentationBadge(
        size: 36,
        displayName: name,
        logoUrl: logoUrl,
        imageInset: 4,
      );
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
