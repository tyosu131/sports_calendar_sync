import 'package:flutter/material.dart';

import '../../domain/policies/team_initial.dart';

/// How a badge stands in when no approved logo is available.
///
/// [monogram] is the historical mark used on GameCard, Home chips, team
/// detail, and schedule tiles. Follow, Search, and League use [neutralMark]
/// so a place-name initial is not treated as team identity.
enum TeamBadgeFallback { monogram, neutralMark }

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
    this.fallback = TeamBadgeFallback.monogram,
  });

  final String displayName;
  final String? logoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final double imageInset;
  final TeamBadgeFallback fallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = foregroundColor ?? theme.colorScheme.onSurface;
    final Widget missing = fallback == TeamBadgeFallback.neutralMark
        ? NeutralTeamMark(color: ink, size: size * 0.62)
        : Center(
            child: Text(
              teamInitial(displayName),
              style: TextStyle(
                color: foregroundColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor:
          backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      child: logoUrl == null || logoUrl!.isEmpty
          ? missing
          : ClipOval(
              child: SizedBox.square(
                dimension: size - imageInset * 2,
                child: Image.network(
                  logoUrl!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => missing,
                ),
              ),
            ),
    );

    if (fallback != TeamBadgeFallback.neutralMark) return avatar;
    return Semantics(
      container: true,
      label: displayName,
      child: ExcludeSemantics(child: avatar),
    );
  }
}

/// Generic team mark drawn in code. It is not a letter, not a club crest,
/// and not a Material glyph.
class NeutralTeamMark extends StatelessWidget {
  const NeutralTeamMark({super.key, required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const Key('neutral-team-mark'),
      size: Size.square(size),
      painter: _NeutralTeamMarkPainter(color),
    );
  }
}

class _NeutralTeamMarkPainter extends CustomPainter {
  const _NeutralTeamMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final head = size.width * 0.16;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.34),
      head,
      paint,
    );
    final shoulders = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.78),
        width: size.width * 0.72,
        height: size.height * 0.36,
      ),
      Radius.circular(size.width * 0.18),
    );
    canvas.drawRRect(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant _NeutralTeamMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
