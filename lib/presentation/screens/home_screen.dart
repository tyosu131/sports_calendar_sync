import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_providers.dart';
import '../../data/providers/game_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/team_providers.dart';
import '../../domain/models/team.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/policies/home_sport_navigation.dart';
import '../../domain/policies/team_display_name_policy.dart';
import '../../domain/policies/team_presentation_policy.dart';
import '../widgets/game_card.dart';
import '../widgets/game_presentation_scope.dart';
import '../widgets/sport_sub_nav_bar.dart';
import '../widgets/team_presentation_badge.dart';
import '../widgets/calendar_sync_button.dart';
import 'sport_league_browser.dart';

/// Home screen: upcoming games for followed teams, grouped by sport.
///
/// [TabBar] and [TabBarView] share the [DefaultTabController], so a tap and a
/// horizontal swipe update one index. Sport tabs add a separate bottom bar
/// with ホーム and リーグ. お気に入り does not.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final tabs = homeSportTabs();

    return DefaultTabController(
      length: tabs.length,
      initialIndex: defaultHomeSportTabIndex(tabs),
      child: _HomeScaffold(tabs: tabs, userAsync: userAsync),
    );
  }
}

class _HomeScaffold extends StatefulWidget {
  const _HomeScaffold({required this.tabs, required this.userAsync});

  final List<HomeSportTab> tabs;
  final AsyncValue<UserProfile?> userAsync;

  @override
  State<_HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<_HomeScaffold> {
  final _subNavIndex = ValueNotifier<int>(0);
  TabController? _controller;
  int? _observedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DefaultTabController.of(context);
    if (identical(_controller, next)) return;
    _controller?.removeListener(_onTabsChanged);
    _controller = next;
    _observedIndex = next.index;
    next.addListener(_onTabsChanged);
  }

  /// Rebuild only after the sport tab index commits, so a swipe is not
  /// interrupted by a new [TabBarView].
  void _onTabsChanged() {
    final index = _controller?.index;
    if (!mounted || index == null || index == _observedIndex) return;
    final tabs = widget.tabs;
    if (homeTabShowsSportSubNav(tabs[index]) && _subNavIndex.value != 0) {
      _subNavIndex.value = 0;
    }
    _observedIndex = index;
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabsChanged);
    _subNavIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = widget.tabs;
    final userAsync = widget.userAsync;
    final tabIndex = _controller?.index ?? defaultHomeSportTabIndex(tabs);
    final showSubNav = homeTabShowsSportSubNav(tabs[tabIndex]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('スポーツカレンダー'),
        actions: [
          // In-app calendar view (not iCalendar sync).
          userAsync.whenOrNull(
                data: (profile) => profile != null
                    ? IconButton(
                        icon: const Icon(Icons.event_note_outlined),
                        tooltip: 'スケジュールを表示',
                        onPressed: () => context.push('/schedule'),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          // Calendar sync button
          userAsync.whenOrNull(
                data: (profile) => !useSampleData && profile != null
                    ? const CalendarSyncButton()
                    : null,
              ) ??
              const SizedBox.shrink(),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          key: const ValueKey('home-sport-tabs'),
          // Four sport labels share the phone width. A scrollable Material 3
          // tab bar adds a 52px start offset plus 16px label padding, which
          // clips 「その他スポーツ」 at 390px.
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          padding: EdgeInsets.zero,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
            fontSize: 13,
            letterSpacing: 0,
          ),
          tabs: [
            for (final tab in tabs)
              Tab(key: ValueKey('home-sport-tab-${tab.id}'), text: tab.label),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          for (final tab in tabs)
            SizedBox.expand(
              key: ValueKey('home-sport-page-${tab.id}'),
              child: _HomeSportPage(
                tab: tab,
                userAsync: userAsync,
                subNavIndex: homeTabShowsSportSubNav(tab) ? _subNavIndex : null,
              ),
            ),
        ],
      ),
      bottomNavigationBar: showSubNav
          ? SportSubNavBar(selectedIndex: _subNavIndex)
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/search'),
        icon: const Icon(Icons.add),
        label: const Text('チームを追加'),
      ),
    );
  }
}

class _HomeSportPage extends StatelessWidget {
  const _HomeSportPage({
    required this.tab,
    required this.userAsync,
    required this.subNavIndex,
  });

  final HomeSportTab tab;
  final AsyncValue<UserProfile?> userAsync;
  final ValueNotifier<int>? subNavIndex;

  @override
  Widget build(BuildContext context) {
    final feed = _HomeSportFeed(tab: tab, userAsync: userAsync);
    final notifier = subNavIndex;
    if (notifier == null) return feed;
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, index, child) {
        if (index == sportSubNavIndexFor(SportSubNavIds.leagues)) {
          return SportLeagueBrowser(tab: tab);
        }
        return child!;
      },
      child: feed,
    );
  }
}

class _HomeSportFeed extends ConsumerWidget {
  const _HomeSportFeed({required this.tab, required this.userAsync});

  final HomeSportTab tab;
  final AsyncValue<UserProfile?> userAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (profile) {
        if (profile == null) {
          return const _SignInPrompt();
        }
        return _HomeContent(
          tab: tab,
          gamesAsync: ref.watch(homeUpcomingGamesProvider),
          followedTeamsAsync: ref.watch(followedTeamsProvider),
        );
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.tab,
    required this.gamesAsync,
    required this.followedTeamsAsync,
  });

  final HomeSportTab tab;
  final AsyncValue<HomeUpcomingGames> gamesAsync;
  final AsyncValue<List<Team>> followedTeamsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return followedTeamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          return const _EmptyFollowedTeams();
        }
        final visibleTeams = teamsForHomeSportTab(teams, tab);
        if (visibleTeams.isEmpty) {
          return _EmptySportFollow(label: tab.label);
        }
        return gamesAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            children: [
              _FollowedTeamsSection(teams: visibleTeams),
              const SizedBox(height: 80),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (homeGames) {
            final games = gamesForHomeSportTab(homeGames.games, tab);
            return GamePresentationScope(
              resolver: homeGames.presentation,
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(followedTeamsProvider);
                  ref.invalidate(presentationMasterProvider);
                  ref.invalidate(gamePresentationProvider);
                  ref.invalidate(upcomingGamesForFollowedTeamsProvider);
                  ref.invalidate(homeUpcomingGamesProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 100),
                  children: [
                    _FollowedTeamsSection(teams: visibleTeams),
                    if (games.isEmpty)
                      const _NoUpcomingGames()
                    else
                      ...games.map((game) => GameCard(game: game)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FollowedTeamsSection extends StatelessWidget {
  const _FollowedTeamsSection({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'フォロー中のチーム',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: teams.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final team = teams[index];
                return _FollowedTeamCard(
                  team: team,
                  backgroundColor: colorScheme.surface,
                  borderColor: colorScheme.outlineVariant,
                  onTap: () => context.push('/team/${team.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowedTeamCard extends StatelessWidget {
  const _FollowedTeamCard({
    required this.team,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final Team team;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logoUrl = teamPresentationLogo(team);
    final displayName = teamDisplayNames.teamName(team);

    return SizedBox(
      width: 196,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                TeamPresentationBadge(
                  size: 48,
                  displayName: displayName,
                  logoUrl: logoUrl,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoUpcomingGames extends StatelessWidget {
  const _NoUpcomingGames();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '直近の試合はありません',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'フォロー中チームの試合が追加されると、ここに表示されます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFollowedTeams extends StatelessWidget {
  const _EmptyFollowedTeams();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports, size: 72, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'フォローしているチームがありません',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '「チームを追加」からお気に入りのチームを登録してください。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search),
                label: const Text('チームを探す'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySportFollow extends StatelessWidget {
  const _EmptySportFollow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports, size: 72, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                '$labelでフォローしているチームがありません',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '「チームを追加」から、このスポーツのチームを登録できます。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search),
                label: const Text('チームを探す'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 72, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'サインインが必要です',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/signin'),
                child: const Text('サインイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
