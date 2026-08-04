import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/primary_app_bar.dart';
import 'package:waretrack_mini/features/settings/bloc/settings_bloc.dart';
import 'package:waretrack_mini/features/settings/bloc/settings_state.dart';
import 'package:waretrack_mini/features/settings/widgets/app_info_card.dart';
import 'package:waretrack_mini/features/settings/widgets/language_setting_card.dart';
import 'package:waretrack_mini/features/settings/widgets/save_transfer_setting_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PrimaryAppBar(title: localizations.initialSettings),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _SettingsMetrics.fromWidth(constraints.maxWidth);
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                final settings = state.settings;
                final bloc = context.read<SettingsBloc>();

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              metrics.pagePadding,
                              metrics.pagePadding,
                              metrics.pagePadding,
                              metrics.pagePadding + bottomInset,
                            ),
                            children: [
                              LanguageSettingCard(
                                language: settings.language,
                                onLanguageChanged: bloc.setLanguage,
                              ),
                              const SizedBox(height: 16),
                              SaveTransferSettingCard(
                                settings: settings.transfer,
                                onSaveFormatChanged: bloc.setSaveFormat,
                                onEmailAddressSaved: bloc.setEmailAddress,
                              ),
                              const SizedBox(height: 16),
                              AppInfoCard(
                                appName: AppBuildConfig.appName,
                                appVersion: '',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SettingsMetrics {
  const _SettingsMetrics({required this.pagePadding});

  final double pagePadding;

  factory _SettingsMetrics.fromWidth(double width) {
    if (width >= 720) {
      return const _SettingsMetrics(pagePadding: 28);
    }

    return const _SettingsMetrics(pagePadding: 16);
  }
}
