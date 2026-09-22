import 'package:flutter/material.dart';

import '../../domain/policies/team_initial.dart';

/// Renders already-resolved team presentation data without making identity or
/// logo-rights decisions.
class TeamPresentationBadge extends StatelessWidget {
  const TeamPresentationBadge({
    super.key,
    required this.displayName,
    this.logoUrl,
    this.size = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.imageInset = 4,
  });

  final String displayName;
  final String? logoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final double imageInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Center(
      child: Text(
        teamInitial(displayName),
        style: TextStyle(
          color: foregroundColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return CircleAvatar(
      radius: size / 2,
      backgroundColor:
          backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      child: logoUrl == null || logoUrl!.isEmpty
          ? fallback
          : ClipOval(
              child: SizedBox.square(
                dimension: size - imageInset * 2,
                child: Image.network(
                  logoUrl!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => fallback,
                ),
              ),
            ),
    );
  }
}
