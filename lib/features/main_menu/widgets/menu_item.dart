import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

enum MainMenuAction {
  receiving,
  shelfPlacement,
  stocktaking,
  movement,
  shipping,
  savedFiles,
  initialSettings,
}

@immutable
final class MainMenuItem {
  const MainMenuItem({
    required this.action,
    required this.icon,
    required this.labelBuilder,
  });

  final MainMenuAction action;
  final IconData icon;
  final String Function(AppLocalizations localizations) labelBuilder;
}
