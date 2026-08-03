import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

class TrialExpiredPage extends StatelessWidget {
  const TrialExpiredPage({super.key, VoidCallback? onClose})
    : _onClose = onClose ?? SystemNavigator.pop;

  final VoidCallback _onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.trialExpiredMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _onClose,
                    child: Text(l10n.closeAppButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
