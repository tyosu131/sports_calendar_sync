import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/ics_url_builder.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/repositories/google_calendar_connection_repository.dart';
import 'google_calendar_connection_tile.dart';
import 'ics_share_sheet.dart';

typedef EnsureCalendarFeed = Future<String> Function();
typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

Uri appleCalendarUri(String httpsUrl) =>
    Uri.parse(httpsUrl.replaceFirst('https://', 'webcal://'));

enum CalendarIcsAction { apple, other }

/// Settings action that retains the same lazy feed behavior as the main sheet.
class CalendarIcsActionButton extends ConsumerWidget {
  const CalendarIcsActionButton({super.key, required this.action});

  final CalendarIcsAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: action == CalendarIcsAction.apple
            ? 'Apple Calendarで開く'
            : '購読URLをコピー・共有',
        icon: Icon(action == CalendarIcsAction.apple
            ? Icons.open_in_new
            : Icons.chevron_right),
        onPressed: () async {
          try {
            final token = await ref
                .read(calendarFeedRepositoryProvider)
                .ensureCalendarFeed();
            final url = IcsUrlBuilder.buildForToken(token);
            if (!context.mounted) return;
            if (action == CalendarIcsAction.other) {
              await IcsShareSheet.show(context, url);
              return;
            }
            final opened = await launchUrl(
              appleCalendarUri(url),
              mode: LaunchMode.externalApplication,
            );
            if (!opened) throw StateError('Apple Calendar could not be opened');
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(action == CalendarIcsAction.apple
                    ? 'Apple Calendarを開けませんでした'
                    : '購読URLを取得できませんでした'),
              ));
            }
          }
        },
      );
}

/// Provider-neutral sync entry point. ICS feeds are issued only after an ICS
/// action is selected; opening this sheet or selecting Google never issues one.
class CalendarSyncSheet extends StatelessWidget {
  const CalendarSyncSheet({
    super.key,
    required this.ensureCalendarFeed,
    this.googleRepository,
    this.launchGoogle,
    this.launchExternal,
  });

  final EnsureCalendarFeed ensureCalendarFeed;
  final GoogleCalendarConnectionRepository? googleRepository;
  final Future<bool> Function(Uri, {LaunchMode mode})? launchGoogle;
  final ExternalUriLauncher? launchExternal;

  static Future<void> show(
    BuildContext context, {
    required EnsureCalendarFeed ensureCalendarFeed,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => CalendarSyncSheet(
          ensureCalendarFeed: ensureCalendarFeed,
        ),
      );

  Future<String> _icsUrl() async =>
      IcsUrlBuilder.buildForToken(await ensureCalendarFeed());

  Future<void> _openApple(BuildContext context) async {
    try {
      final uri = appleCalendarUri(await _icsUrl());
      final opened = await (launchExternal ??
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication))(uri);
      if (!opened) throw StateError('Apple Calendar could not be opened');
    } catch (_) {
      if (context.mounted) _showError(context, 'Apple Calendarを開けませんでした');
    }
  }

  Future<void> _openOther(BuildContext context) async {
    try {
      final url = await _icsUrl();
      if (context.mounted) await IcsShareSheet.show(context, url);
    } catch (_) {
      if (context.mounted) _showError(context, '購読URLを取得できませんでした');
    }
  }

  void _showError(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('カレンダーに同期',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
              ),
              const SizedBox(height: 8),
              GoogleCalendarConnectionTile(
                repository: googleRepository,
                launch: launchGoogle ?? launchUrl,
                mode: GoogleCalendarTileMode.sync,
              ),
              ListTile(
                leading: const Icon(Icons.apple),
                title: const Text('Apple Calendar'),
                subtitle: const Text('Apple Calendarで購読'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openApple(context),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('その他のカレンダー'),
                subtitle: const Text('購読URLをコピー・共有'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openOther(context),
              ),
            ],
          ),
        ),
      );
}
