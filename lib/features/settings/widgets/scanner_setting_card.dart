import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/settings/widgets/setting_switch_tile.dart';
import 'package:waretrack_mini/features/settings/widgets/settings_section_card.dart';

class ScannerSettingCard extends StatelessWidget {
  const ScannerSettingCard({
    super.key,
    required this.settings,
    required this.onScanSoundChanged,
    required this.onAutoScanChanged,
    required this.onDuplicateProtectionChanged,
    required this.onCameraResetAfterDetectionChanged,
    required this.onFastScanModeChanged,
  });

  final ScannerSettings settings;
  final ValueChanged<bool> onScanSoundChanged;
  final ValueChanged<bool> onAutoScanChanged;
  final ValueChanged<bool> onDuplicateProtectionChanged;
  final ValueChanged<bool> onCameraResetAfterDetectionChanged;
  final ValueChanged<bool> onFastScanModeChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SettingsSectionCard(
      title: localizations.scannerSettings,
      child: Column(
        children: [
          SettingSwitchTile(
            title: localizations.scanSound,
            value: settings.scanSound,
            onChanged: onScanSoundChanged,
          ),
          SettingSwitchTile(
            title: localizations.autoScan,
            value: settings.autoScan,
            onChanged: onAutoScanChanged,
          ),
          SettingSwitchTile(
            title: localizations.duplicateProtection,
            value: settings.duplicateProtection,
            onChanged: onDuplicateProtectionChanged,
          ),
          SettingSwitchTile(
            title: localizations.cameraReset,
            value: settings.cameraResetAfterDetection,
            onChanged: onCameraResetAfterDetectionChanged,
          ),
          SettingSwitchTile(
            title: localizations.fastScanMode,
            value: settings.fastScanMode,
            onChanged: onFastScanModeChanged,
          ),
        ],
      ),
    );
  }
}
