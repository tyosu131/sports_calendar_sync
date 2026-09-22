import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import 'calendar_sync_sheet.dart';

/// Opens provider choices without issuing an ICS feed token.
class CalendarSyncButton extends ConsumerWidget {
  const CalendarSyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        icon: const Icon(Icons.sync_alt),
        tooltip: 'フォロー中のチームをカレンダーに同期',
        onPressed: () => _openSheet(context, ref),
      );

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    if (ref.read(currentUserProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カレンダー同期にはサインインが必要です')),
      );
      return;
    }
    await CalendarSyncSheet.show(
      context,
      ensureCalendarFeed:
          ref.read(calendarFeedRepositoryProvider).ensureCalendarFeed,
    );
  }
}
