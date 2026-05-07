import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet for sharing/copying the iCalendar subscription URL.
class IcsShareSheet extends StatelessWidget {
  const IcsShareSheet({super.key, required this.icsUrl});

  final String icsUrl;

  static Future<void> show(BuildContext context, String icsUrl) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IcsShareSheet(icsUrl: icsUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'カレンダーに同期',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'このURLをカレンダーアプリに登録すると、試合日程が自動で同期されます。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // URL display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      icsUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'URLをコピー',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: icsUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URLをコピーしました')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons
            _ActionButton(
              icon: Icons.calendar_today,
              label: 'Googleカレンダーで開く',
              onTap: () => _openGoogleCalendar(context),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.apple,
              label: 'Appleカレンダーで開く',
              onTap: () => _openAppleCalendar(context),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.share,
              label: 'URLをシェア',
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text: icsUrl,
                  subject: 'スポーツカレンダー購読URL',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleCalendar(BuildContext context) async {
    final encoded = Uri.encodeComponent(icsUrl);
    final uri = Uri.parse(
        'https://www.google.com/calendar/render?cid=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAppleCalendar(BuildContext context) async {
    // webcal:// scheme triggers Apple Calendar on iOS/macOS
    final webcalUrl = icsUrl.replaceFirst('https://', 'webcal://');
    final uri = Uri.parse(webcalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
