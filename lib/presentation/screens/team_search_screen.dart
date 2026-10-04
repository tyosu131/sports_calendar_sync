import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_providers.dart';
import '../../data/providers/team_providers.dart';
import '../../domain/policies/home_sport_navigation.dart';
import '../widgets/follow_toggle.dart';
import '../widgets/sport_sub_nav_bar.dart';
import '../widgets/team_list_tile.dart';
import 'sport_league_browser.dart';

/// Search and follow discovery. Mirrors Home sport tabs and ホーム | リーグ.
class TeamSearchScreen extends ConsumerWidget {
  const TeamSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = followDiscoverySportTabs();

    return DefaultTabController(
      length: tabs.length,
      initialIndex: defaultHomeSportTabIndex(tabs),
      child: _TeamSearchScaffold(tabs: tabs),
    );
  }
}

class _TeamSearchScaffold extends ConsumerStatefulWidget {
  const _TeamSearchScaffold({required this.tabs});

  final List<HomeSportTab> tabs;

  @override
  ConsumerState<_TeamSearchScaffold> createState() =>
      _TeamSearchScaffoldState();
}

class _TeamSearchScaffoldState extends ConsumerState<_TeamSearchScaffold> {
  final _subNavIndex = ValueNotifier<int>(0);
  final _searchController = TextEditingController();
  TabController? _controller;
  int? _observedIndex;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    ref.read(teamSearchQueryProvider.notifier).state = _searchController.text;
  }

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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = widget.tabs;
    final tabIndex = _controller?.index ?? defaultHomeSportTabIndex(tabs);
    final showSubNav = homeTabShowsSportSubNav(tabs[tabIndex]);

    return ValueListenableBuilder<int>(
      valueListenable: _subNavIndex,
      builder: (context, subIndex, _) {
        final showingLeagues =
            showSubNav &&
            subIndex == sportSubNavIndexFor(SportSubNavIds.leagues);
        final showTeamSearchBar =
            !tabs[tabIndex].showsAllSports && !showingLeagues;

        return Scaffold(
          appBar: AppBar(
            title: const Text('チームを探す'),
            bottom: TabBar(
              key: const ValueKey('team-search-sport-tabs'),
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
                  Tab(
                    key: ValueKey('team-search-tab-${tab.id}'),
                    text: tab.label,
                  ),
              ],
            ),
          ),
          body: Column(
            children: [
              if (showTeamSearchBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _TeamNameSearchBar(
                    controller: _searchController,
                    fieldKey: ValueKey(
                      'team-search-query-${tabs[tabIndex].id}',
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final tab in tabs)
                      SizedBox.expand(
                        key: ValueKey('team-search-page-${tab.id}'),
                        child: _TeamSearchPage(
                          tab: tab,
                          isActive: tab.id == tabs[tabIndex].id,
                          subNavIndex: homeTabShowsSportSubNav(tab)
                              ? _subNavIndex
                              : null,
                          searchController: tab.showsAllSports
                              ? _searchController
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: showSubNav
              ? SportSubNavBar(selectedIndex: _subNavIndex)
              : null,
        );
      },
    );
  }
}

class _TeamSearchPage extends ConsumerWidget {
  const _TeamSearchPage({
    required this.tab,
    required this.isActive,
    required this.subNavIndex,
    required this.searchController,
  });

  final HomeSportTab tab;
  final bool isActive;
  final ValueNotifier<int>? subNavIndex;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tab.showsAllSports) {
      return _FollowingSearchBody(searchController: searchController!);
    }
    final notifier = subNavIndex!;
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, index, child) {
        if (isActive && index == sportSubNavIndexFor(SportSubNavIds.leagues)) {
          return SportLeagueBrowser(tab: tab);
        }
        return child!;
      },
      child: _SportTeamSearchResults(sportTabId: tab.id),
    );
  }
}

class _FollowingSearchBody extends StatelessWidget {
  const _FollowingSearchBody({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _TeamNameSearchBar(
            controller: searchController,
            fieldKey: const ValueKey('team-search-query-following'),
          ),
        ),
        const Expanded(
          child: _SportTeamSearchResults(sportTabId: HomeSportTabIds.favorites),
        ),
      ],
    );
  }
}

class _TeamNameSearchBar extends StatelessWidget {
  const _TeamNameSearchBar({required this.controller, required this.fieldKey});

  final TextEditingController controller;
  final Key fieldKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return SearchBar(
          key: fieldKey,
          controller: controller,
          hintText: 'チーム名で検索...',
          leading: const Icon(Icons.search),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          trailing: [
            if (value.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: '検索をクリア',
                onPressed: controller.clear,
              ),
          ],
        );
      },
    );
  }
}

class _SportTeamSearchResults extends ConsumerWidget {
  const _SportTeamSearchResults({required this.sportTabId});

  final String sportTabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(teamSearchResultsProvider(sportTabId));
    final searchQuery = ref.watch(teamSearchQueryProvider);
    final session = watchFollowInteraction(ref);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (teams) {
        if (teams.isEmpty) {
          final followedOnly = sportTabId == HomeSportTabIds.favorites;
          final emptyMessage = followedOnly
              ? (searchQuery.trim().isEmpty
                    ? 'フォロー中のチームはありません'
                    : '条件に合うフォロー中のチームはありません')
              : 'チームが見つかりませんでした';
          return _TeamSearchEmptyState(message: emptyMessage);
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final isFollowing = session.isFollowing(team.id);
            return TeamListTile(
              team: team,
              isFollowing: isFollowing,
              onTap: () => context.push('/team/${team.id}'),
              onFollowToggle: () => toggleFollow(
                context,
                ref,
                session,
                team.id,
                team.competitionKey,
              ),
            );
          },
        );
      },
    );
  }
}

class _TeamSearchEmptyState extends StatelessWidget {
  const _TeamSearchEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 56,
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
      ),
    );
  }
}
