import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/settings/widgets/setting_option_tile.dart';
import 'package:waretrack_mini/features/settings/widgets/settings_section_card.dart';
import 'package:waretrack_mini/features/settings/widgets/settings_text_field.dart';

class SaveTransferSettingCard extends StatefulWidget {
  const SaveTransferSettingCard({
    super.key,
    required this.settings,
    required this.onSaveFormatChanged,
    required this.onEmailAddressSaved,
  });

  final TransferSettings settings;
  final ValueChanged<SaveFormat> onSaveFormatChanged;

  /// Persists the email address. Called only when the Save button is pressed.
  final ValueChanged<String> onEmailAddressSaved;

  @override
  State<SaveTransferSettingCard> createState() =>
      _SaveTransferSettingCardState();
}

class _SaveTransferSettingCardState extends State<SaveTransferSettingCard> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final TextEditingController _emailController;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.settings.emailAddress,
    );
  }

  @override
  void didUpdateWidget(covariant SaveTransferSettingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync if the persisted email changes elsewhere, but
    // never while the user is typing an unsaved draft.
    if (oldWidget.settings.emailAddress != widget.settings.emailAddress) {
      _syncController(_emailController, widget.settings.emailAddress);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SettingsSectionCard(
      title: localizations.saveTransfer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingOptionTile<SaveFormat>(
            label: localizations.saveFormat,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<SaveFormat>(
                segments: [
                  ButtonSegment(
                    value: SaveFormat.csv,
                    label: Text(localizations.csv),
                  ),
                  ButtonSegment(
                    value: SaveFormat.excel,
                    label: Text(localizations.excel),
                  ),
                ],
                selected: {
                  widget.settings.saveFormat == SaveFormat.excel
                      ? SaveFormat.excel
                      : SaveFormat.csv,
                },
                onSelectionChanged: (value) =>
                    widget.onSaveFormatChanged(value.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.transferMethod,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SettingsTextField(
            controller: _emailController,
            label: localizations.emailAddress,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_statusMessage != null) {
                setState(() => _statusMessage = null);
              }
            },
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _statusIsError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: FilledButton(
              onPressed: () => _saveEmail(localizations),
              child: Text(localizations.settings),
            ),
          ),
        ],
      ),
    );
  }

  void _saveEmail(AppLocalizations localizations) {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _statusMessage = localizations.emailRequired;
        _statusIsError = true;
      });
      return;
    }

    if (!_emailPattern.hasMatch(email)) {
      setState(() {
        _statusMessage = localizations.invalidEmail;
        _statusIsError = true;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    widget.onEmailAddressSaved(email);

    setState(() {
      _statusMessage = localizations.settingsSaved;
      _statusIsError = false;
    });
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
