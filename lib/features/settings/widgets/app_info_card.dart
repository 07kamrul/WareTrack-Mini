import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/settings/widgets/settings_section_card.dart';

class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.appName,
    required this.appVersion,
  });

  final String appName;
  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SettingsSectionCard(
      title: localizations.appInformation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoItem(label: localizations.appName, value: appName),
          const SizedBox(height: 12),
          _InfoItem(label: localizations.appVersion, value: appVersion),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}
