import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/app_strings.dart';

/// Actions for calendar clients that consume a generic ICS subscription URL.
///
/// The personalized URL is intentionally never rendered on screen.
class IcsShareSheet extends StatelessWidget {
  const IcsShareSheet({super.key, required this.icsUrl});

  final String icsUrl;

  static Future<void> show(BuildContext context, String icsUrl) =>
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => IcsShareSheet(icsUrl: icsUrl),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('その他のカレンダー'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 8),
              Text(tr('お使いのカレンダーに購読URLを登録してください。')),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(tr('購読URLをコピー')),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: icsUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('購読URLをコピーしました'))),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(tr('URLをシェア')),
                onTap: () => SharePlus.instance.share(ShareParams(
                  text: icsUrl,
                  subject: tr('スポーツカレンダー購読URL'),
                )),
              ),
            ],
          ),
        ),
      );
}
