import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../widgets/calendar_sync_sheet.dart';
import '../widgets/google_calendar_connection_tile.dart';
import '../widgets/public_policy_links.dart';
import '../../core/config/app_strings.dart';

/// Settings screen: account info, calendar sync URL, sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: SettingsBackButton(),
        title: Text(tr('設定')),
      ),
      body: userAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(trArgs('エラー: {e}', {'e': '$e'}))),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () => context.push('/signin'),
                    child: Text(tr('サインイン')),
                  ),
                  PublicPolicyLinks(),
                ],
              ),
            );
          }

          return ListView(
            children: [
              // Account section
              _SectionHeader(title: tr('アカウント')),
              ListTile(
                leading: profile.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profile.photoUrl!),
                      )
                    : CircleAvatar(child: Icon(Icons.person)),
                title: Text(profile.displayName ?? tr('ユーザー')),
                subtitle: Text(profile.email),
              ),
              Divider(),

              if (!useSampleData) ...[
                // Personalized calendar sync is an authenticated production
                // flow; sample mode keeps using its local ICS builder.
                CalendarSyncSettingsSection(),
                Divider(),
              ],

              // App section
              _SectionHeader(title: tr('アプリ')),
              ListTile(
                leading: Icon(Icons.language),
                title: Text(tr('名前の言語')),
                subtitle: Text(_languageLabel(profile.preferredLanguage)),
                trailing: Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(
                  context,
                  ref,
                  profile.uid,
                  profile.preferredLanguage,
                ),
              ),
              Divider(),

              // Sign out
              const PublicPolicyLinks(),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  tr('サインアウト'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    String uid,
    String current,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('名前の言語')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ja'),
            child: Row(
              children: [
                if (current != 'en') const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_languageLabel('ja'))),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'en'),
            child: Row(
              children: [
                if (current == 'en') const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_languageLabel('en'))),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      await ref
          .read(userRepositoryProvider)
          .upsertProfile(
            (await ref.read(userRepositoryProvider).fetchProfile(uid))!
                .copyWith(preferredLanguage: selected),
          );
    }
  }

  /// `ja` is the automatic rule; `en` makes every name English.
  static String _languageLabel(String? value) =>
      value == 'en' ? tr('English（すべて英語）') : tr('自動（日本のチーム・選手・会場は日本語、海外は英語）');

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('サインアウト')),
        content: Text(tr('サインアウトしますか？')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('キャンセル')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('サインアウト')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(userRepositoryProvider).signOut();
      if (context.mounted) context.go('/');
    }
  }
}

/// Keeps the usual pop behavior while giving direct/deep-link entries a
/// deterministic way back to Home.
class SettingsBackButton extends StatelessWidget {
  const SettingsBackButton({super.key});

  @override
  Widget build(BuildContext context) => BackButton(
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    },
  );
}

/// Distinguishes URL-based Apple/generic subscriptions from direct Google sync.
class CalendarSyncSettingsSection extends StatelessWidget {
  const CalendarSyncSettingsSection({
    super.key,
    this.appleAction = const CalendarIcsActionButton(
      action: CalendarIcsAction.apple,
    ),
    this.otherAction = const CalendarIcsActionButton(
      action: CalendarIcsAction.other,
    ),
    this.googleCalendarTile = const GoogleCalendarConnectionTile(),
  });

  final Widget appleAction;
  final Widget otherAction;
  final Widget googleCalendarTile;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SectionHeader(title: tr('カレンダー同期')),
      googleCalendarTile,
      ListTile(
        leading: const Icon(Icons.apple),
        title: const Text('Apple Calendar'),
        subtitle: Text(tr('Apple Calendarで購読')),
        trailing: appleAction,
      ),
      ListTile(
        leading: const Icon(Icons.calendar_month),
        title: Text(tr('その他のカレンダー')),
        subtitle: Text(tr('ICS購読URLをコピー・共有')),
        trailing: otherAction,
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
