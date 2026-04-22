import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/ics_url_builder.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../widgets/ics_share_sheet.dart';

/// Settings screen: account info, calendar sync URL, sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.push('/signin'),
                child: const Text('サインイン'),
              ),
            );
          }

          final icsUrl = IcsUrlBuilder.buildForUser(profile.uid);

          return ListView(
            children: [
              // Account section
              _SectionHeader(title: 'アカウント'),
              ListTile(
                leading: profile.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profile.photoUrl!),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(profile.displayName ?? 'ユーザー'),
                subtitle: Text(profile.email),
              ),
              const Divider(),

              // Calendar sync section
              _SectionHeader(title: 'カレンダー同期'),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('iCalendar URL'),
                subtitle: Text(
                  icsUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => IcsShareSheet.show(context, icsUrl),
              ),
              const Divider(),

              // App section
              _SectionHeader(title: 'アプリ'),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('言語'),
                subtitle: Text(
                  profile.preferredLanguage == 'ja' ? '日本語' : 'English',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context, ref, profile.uid,
                    profile.preferredLanguage),
              ),
              const Divider(),

              // Sign out
              ListTile(
                leading: Icon(Icons.logout,
                    color: theme.colorScheme.error),
                title: Text(
                  'サインアウト',
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
        title: const Text('言語を選択'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ja'),
            child: Row(
              children: [
                if (current == 'ja') const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                const Text('日本語'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'en'),
            child: Row(
              children: [
                if (current == 'en') const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                const Text('English'),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      await ref.read(userRepositoryProvider).upsertProfile(
            (await ref.read(userRepositoryProvider).fetchProfile(uid))!
                .copyWith(preferredLanguage: selected),
          );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('サインアウト'),
        content: const Text('サインアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('サインアウト'),
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
