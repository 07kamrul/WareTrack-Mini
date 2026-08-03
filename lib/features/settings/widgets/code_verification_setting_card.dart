import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/api_services/auth_service.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/dialog_message_text.dart';
import 'package:waretrack_mini/core/widgets/offline_dialog.dart';
import 'package:waretrack_mini/features/settings/widgets/settings_section_card.dart';
import 'package:waretrack_mini/features/settings/widgets/settings_text_field.dart';

class CodeVerificationSettingCard extends StatefulWidget {
  const CodeVerificationSettingCard({super.key});

  @override
  State<CodeVerificationSettingCard> createState() =>
      _CodeVerificationSettingCardState();
}

class _CodeVerificationSettingCardState
    extends State<CodeVerificationSettingCard> {
  final TextEditingController _codeController = TextEditingController();

  String? _message;
  bool _isError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();

    if (code.isEmpty) {
      setState(() {
        _message = l10n.approvalCodeRequired;
        _isError = true;
      });
      return;
    }

    setState(() {
      _message = null;
      _isError = false;
      _isLoading = true;
    });

    try {
      await sl<AuthService>().codeVerify(code);
      if (!mounted) return;

      // Clear any previous inline error message.
      setState(() {
        _message = null;
        _isError = false;
      });

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: DialogMessageText(l10n.completed),
          content: DialogMessageText(l10n.approvalCodeVerifiedMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 1. Close popup
                _codeController.clear(); // 2. Clear input
                FocusManager.instance.primaryFocus
                    ?.unfocus(); // 3. Release focus & hide keyboard
                setState(() {
                  _message = null;
                  _isError = false;
                });
              },
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;

      if (!maybeShowOfflineDialog(context, error)) {
        setState(() {
          _message = _cleanErrorMessage(error);
          _isError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanErrorMessage(Object error) {
    var message = error.toString();
    while (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SettingsSectionCard(
      title: l10n.codeVerification,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.codeVerificationSettingDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SettingsTextField(
                  controller: _codeController,
                  label: l10n.code,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_message != null) {
                      setState(() => _message = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.submit),
                ),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
