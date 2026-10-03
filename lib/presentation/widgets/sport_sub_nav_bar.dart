import 'package:flutter/material.dart';

import '../../domain/policies/home_sport_navigation.dart';

/// Fixed ホーム | リーグ bar for one sport tab.
///
/// Selected state uses a filled icon, a heavier label, and the indicator.
/// Color is not the only difference. Labels stay visible.
class SportSubNavBar extends StatelessWidget {
  const SportSubNavBar({super.key, required this.selectedIndex});

  final ValueNotifier<int> selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: selectedIndex,
      builder: (context, index, _) {
        final safeIndex = index < 0 || index >= sportSubNavDestinations.length
            ? 0
            : index;
        return NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            key: const ValueKey('sport-sub-nav'),
            selectedIndex: safeIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (value) {
              if (selectedIndex.value == value) return;
              selectedIndex.value = value;
            },
            destinations: [
              for (final destination in sportSubNavDestinations)
                NavigationDestination(
                  key: ValueKey('sport-sub-nav-${destination.id}'),
                  icon: Icon(_outlinedIcon(destination.id)),
                  selectedIcon: Icon(_filledIcon(destination.id)),
                  label: destination.label,
                  tooltip: destination.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

IconData _outlinedIcon(String id) {
  return id == SportSubNavIds.leagues
      ? Icons.emoji_events_outlined
      : Icons.home_outlined;
}

IconData _filledIcon(String id) {
  return id == SportSubNavIds.leagues ? Icons.emoji_events : Icons.home;
}
