import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/settings/widgets/setting_option_tile.dart';
import 'package:waretrack_mini/features/settings/widgets/settings_section_card.dart';

class LanguageSettingCard extends StatelessWidget {
  const LanguageSettingCard({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SettingsSectionCard(
      title: localizations.language,
      child: SettingOptionTile<AppLanguage>(
        label: localizations.currentLanguage,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment(
                value: AppLanguage.english,
                label: Text(localizations.english),
              ),
              ButtonSegment(
                value: AppLanguage.bangla,
                label: Text(localizations.bangla),
              ),
            ],
            selected: {language},
            onSelectionChanged: (value) => onLanguageChanged(value.first),
            showSelectedIcon: false,
          ),
        ),
      ),
    );
  }
}
