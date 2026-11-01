import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_strings.dart';

/// Must match the reviewed Hosting/Branding origin for the released build.
/// The default is the prepared site, not evidence that it has been published.
const publicSiteUrl = String.fromEnvironment(
  'PUBLIC_SITE_URL',
  defaultValue: 'https://sports-calendar-sync.com',
);

Uri publicPolicyUri(String path, {String origin = publicSiteUrl}) {
  final base = Uri.tryParse(origin);
  if (base == null ||
      base.scheme != 'https' ||
      base.host.isEmpty ||
      base.userInfo.isNotEmpty ||
      base.hasQuery ||
      base.hasFragment ||
      (base.path.isNotEmpty && base.path != '/') ||
      !const ['/', '/privacy', '/terms'].contains(path)) {
    throw FormatException('Invalid public policy URL');
  }
  return base.resolve(path);
}

/// Public information remains accessible without connecting Google Calendar.
class PublicPolicyLinks extends StatelessWidget {
  const PublicPolicyLinks({super.key, this.openUrl});

  final Future<bool> Function(Uri)? openUrl;

  Future<void> _open(BuildContext context, String path) async {
    try {
      final uri = publicPolicyUri(path);
      final opened =
          await (openUrl?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (opened) return;
    } catch (_) {
      // Never surface platform errors or URI payloads in the user interface.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('ページを開けませんでした。時間をおいて再度お試しください。'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      for (final (label, path) in [
        (tr('アプリについて'), '/'),
        (tr('プライバシーポリシー'), '/privacy'),
        (tr('利用規約'), '/terms'),
      ])
        TextButton(onPressed: () => _open(context, path), child: Text(label)),
    ],
  );
}
