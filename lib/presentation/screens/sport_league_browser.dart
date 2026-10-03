import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/sport_definition.dart';
import '../../domain/policies/home_sport_navigation.dart';
import '../theme/presentation_decoration.dart';

/// League list for the current sport tab.
///
/// Competitions come from [SportsRegistry] through [competitionsForHomeSportTab].
/// A row pushes the team list; it does not add a bottom-nav destination.
class SportLeagueBrowser extends StatefulWidget {
  const SportLeagueBrowser({super.key, required this.tab});

  final HomeSportTab tab;

  @override
  State<SportLeagueBrowser> createState() => _SportLeagueBrowserState();
}

class _SportLeagueBrowserState extends State<SportLeagueBrowser> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final competitions = filterSportCompetitions(
      competitionsForHomeSportTab(widget.tab),
      _query,
    );
    final hasAny = competitionsForHomeSportTab(widget.tab).isNotEmpty;

    return ListView(
      key: ValueKey('sport-league-list-${widget.tab.id}'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          'リーグ',
          key: ValueKey('sport-league-title-${widget.tab.id}'),
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        SearchBar(
          key: ValueKey('sport-league-search-${widget.tab.id}'),
          controller: _queryController,
          hintText: 'リーグを検索',
          leading: const Icon(Icons.search),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          trailing: [
            if (_query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: '検索をクリア',
                onPressed: () {
                  _queryController.clear();
                  setState(() => _query = '');
                },
              ),
          ],
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 16),
        if (!hasAny)
          const _LeagueMessage(message: '表示できるリーグがありません')
        else if (competitions.isEmpty)
          const _LeagueMessage(message: '一致するリーグはありません')
        else
          for (final competition in competitions)
            _LeagueRow(
              competition: competition,
              onTap: () =>
                  context.push('/league/${competition.competitionKey}'),
            ),
      ],
    );
  }
}

class _LeagueRow extends StatelessWidget {
  const _LeagueRow({required this.competition, required this.onTap});

  final SportDefinition competition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = competitionBadgeLabel(competition);
    final accent = competitionBrowseAccent(competition.competitionKey);
    return Padding(
      key: ValueKey('sport-league-${competition.competitionKey}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _NeutralCompetitionBadge(label: badge, color: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    competition.displayNameJa,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeutralCompetitionBadge extends StatelessWidget {
  const _NeutralCompetitionBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeagueMessage extends StatelessWidget {
  const _LeagueMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
