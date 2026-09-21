import 'package:flutter/widgets.dart';

import '../../domain/models/game.dart';
import '../../domain/policies/team_presentation_policy.dart';

/// Screen-owned metadata; cards never perform repository reads.
class GamePresentationScope extends InheritedWidget {
  const GamePresentationScope({
    super.key,
    required this.resolver,
    required super.child,
  });
  final TeamPresentationLogoResolver resolver;

  static String? logo(BuildContext context, Game game, bool home) =>
      publicTeamLogoUrl(
        (context
                    .dependOnInheritedWidgetOfExactType<GamePresentationScope>()
                    ?.resolver ??
                TeamPresentationLogoResolver(const []))
            .side(game, home),
      );

  @override
  bool updateShouldNotify(GamePresentationScope oldWidget) =>
      resolver != oldWidget.resolver;
}
