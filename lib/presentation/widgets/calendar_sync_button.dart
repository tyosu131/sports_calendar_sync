import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ics_url_builder.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import 'ics_share_sheet.dart';

/// Issues the current user's feed token and opens subscription options.
class CalendarSyncButton extends ConsumerStatefulWidget {
  const CalendarSyncButton({super.key});

  @override
  ConsumerState<CalendarSyncButton> createState() =>
      _CalendarSyncButtonState();
}

class _CalendarSyncButtonState extends ConsumerState<CalendarSyncButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.calendar_month),
      tooltip: 'フォロー中のチームをカレンダーに同期',
      onPressed: _loading ? null : _openFeed,
    );
  }

  Future<void> _openFeed() async {
    if (ref.read(currentUserProvider) == null) {
      _showError('カレンダー同期にはサインインが必要です');
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await ref
          .read(calendarFeedRepositoryProvider)
          .ensureCalendarFeed();
      if (!mounted) return;
      await IcsShareSheet.show(context, IcsUrlBuilder.buildForToken(token));
    } catch (_) {
      if (mounted) _showError('カレンダーURLを取得できませんでした。もう一度お試しください');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
