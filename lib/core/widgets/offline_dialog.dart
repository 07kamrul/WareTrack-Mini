import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/api_services/api_connection_guard.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/validation_error_dialog.dart';

/// Single source of truth for the dialog shown whenever an API request fails
/// because of a network/connection problem (no internet, timeout, socket
/// failure, DNS lookup failure, etc.). Shown app-wide so the wording stays
/// consistent across every screen.
void showOfflineDialog(BuildContext context) {
  showValidationErrorDialog(
    context,
    AppLocalizations.of(context).offlineMessage,
  );
}

/// Centralized network-error handler for the UI layer.
///
/// If [error] is a connectivity-related failure, shows the unified offline
/// dialog and returns `true` so the caller can stop further (business-error)
/// handling. Returns `false` for server/business errors (400/401/403/404/422/
/// 500, etc.), letting the caller handle those as before.
///
/// Use this everywhere an API call is awaited instead of re-implementing the
/// `isApiOfflineError(...) -> showOfflineDialog(...)` check per screen.
bool maybeShowOfflineDialog(BuildContext context, Object error) {
  if (!isApiOfflineError(error)) {
    return false;
  }

  showOfflineDialog(context);
  return true;
}
