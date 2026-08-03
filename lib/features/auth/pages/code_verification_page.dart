import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart'; // For dependency injection 'sl'
import 'package:waretrack_mini/core/services/trial_service.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/widgets/trial_expired_page.dart';
import 'package:waretrack_mini/features/auth/bloc/auth_bloc.dart';
import 'package:waretrack_mini/features/auth/bloc/auth_event.dart';
import 'package:waretrack_mini/features/auth/bloc/auth_state.dart';
import 'package:waretrack_mini/features/auth/widgets/auth_field.dart';
import 'package:waretrack_mini/features/auth/widgets/auth_shell.dart';
import 'package:waretrack_mini/features/main_menu/pages/home_page.dart';
import 'package:waretrack_mini/core/widgets/validation_error_dialog.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/offline_dialog.dart';

class CodeVerificationPage extends StatefulWidget {
  const CodeVerificationPage({super.key});

  @override
  State<CodeVerificationPage> createState() => _CodeVerificationPageState();
}

class _CodeVerificationPageState extends State<CodeVerificationPage> {
  final TextEditingController _codeController = TextEditingController();
  String? _validationErrorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _validateAndSubmit(BuildContext context) {
    final code = _codeController.text.trim();

    setState(() {
      _validationErrorMessage = null;
    });

    final l10n = AppLocalizations.of(context);

    if (code.isEmpty) {
      setState(() {
        _validationErrorMessage = l10n.authCodeRequired;
      });
      return;
    }

    final RegExp digitRegex = RegExp(r'^\d{8}$');
    if (!digitRegex.hasMatch(code)) {
      setState(() {
        _validationErrorMessage = l10n.authCodeInvalidFormat;
      });
      return;
    }

    context.read<AuthBloc>().add(VerifyCodeEvent(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthSuccess) {
            Widget nextPage = const HomePage();
            if (AppBuildConfig.isTrial) {
              try {
                final result = await sl<TrialService>().resolveTrialStatus();
                // Fail closed: only a confirmed-active trial reaches Home.
                // An unresolved check (e.g. the device-verify call went
                // offline right after code-verify) must not be treated as
                // active — first activation requires a server-confirmed
                // registration.
                if (result != TrialGateResult.active) {
                  nextPage = const TrialExpiredPage();
                }
              } on Exception catch (e) {
                if (!context.mounted) return;
                if (!maybeShowOfflineDialog(context, e)) {
                  showValidationErrorDialog(context, e.toString());
                }
                return;
              }
            }
            if (!context.mounted) return;
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => nextPage),
              (route) => false,
            );
          } else if (state is AuthFailure) {
            final isOffline = maybeShowOfflineDialog(context, state.message);
            if (!isOffline) {
              showValidationErrorDialog(context, state.message);
            }
            setState(() {
              _validationErrorMessage = isOffline ? null : state.message;
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                return;
              }
              SystemNavigator.pop();
            },
            child: AuthShell(
              appBarTitle: l10n.codeVerification,
              title: AppBuildConfig.displayName(l10n.systemTitle),
              subtitle: l10n.codeVerificationDescription,
              showBackButton: false,
              children: [
                AuthField(
                  label: l10n.code,
                  keyboardType: TextInputType.number,
                  controller: _codeController,
                  enabled: !isLoading,
                  errorText: _validationErrorMessage,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _validateAndSubmit(context),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(isLoading ? '...' : l10n.submit),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
