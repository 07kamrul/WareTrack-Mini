import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/api_services/api_environment.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/app_router.dart';
import 'package:waretrack_mini/core/services/manual_service.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/primary_app_bar.dart';
import 'package:waretrack_mini/features/main_menu/widgets/menu_item.dart';
import 'package:waretrack_mini/features/main_menu/widgets/menu_card.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  static final List<MainMenuItem> _items = [
    MainMenuItem(
      action: MainMenuAction.receiving,
      icon: Icons.inventory_2_outlined,
      labelBuilder: (localizations) => localizations.receiving,
    ),
    MainMenuItem(
      action: MainMenuAction.shipping,
      icon: Icons.local_shipping_outlined,
      labelBuilder: (localizations) => localizations.shipping,
    ),
    MainMenuItem(
      action: MainMenuAction.shelfPlacement,
      icon: Icons.shelves,
      labelBuilder: (localizations) => localizations.shelfPlacement,
    ),
    MainMenuItem(
      action: MainMenuAction.stocktaking,
      icon: Icons.fact_check_outlined,
      labelBuilder: (localizations) => localizations.stocktaking,
    ),
    MainMenuItem(
      action: MainMenuAction.savedFiles,
      icon: Icons.folder_copy_outlined,
      labelBuilder: (localizations) => localizations.savedFileList,
    ),
    MainMenuItem(
      action: MainMenuAction.initialSettings,
      icon: Icons.settings_outlined,
      labelBuilder: (localizations) => localizations.initialSettings,
    ),
  ];

  /// 棚入れ (shelf placement) is only available on demo440; hide it for
  /// every other API environment.
  static List<MainMenuItem> get _visibleItems => _items
      .where(
        (item) =>
            item.action != MainMenuAction.shelfPlacement ||
            BaseApi.current == ApiEnvironment.demo440,
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // final colorScheme = Theme.of(context).colorScheme;
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PrimaryAppBar(
        title: localizations.mainMenu,
        showBackButton: false,
        // The manual PDF is offered on demo440, jarocDemo, and every trial
        // build; the remaining base environments (demo395, jarocClient,
        // jarocDev, ...) hide the help button entirely.
        showHelpButton:
            BaseApi.current == ApiEnvironment.demo440 ||
            BaseApi.current == ApiEnvironment.jarocDemo ||
            BaseApi.isTrial,
        onHelpPressed: () => ManualService.openManual(context),
        leading: BaseApi.isTrial
            ? const TrialActionButton(label: 'TRIAL')
            : FutureBuilder<String?>(
                future: sl<LocalStorage>().readString(kCode),
                builder: (context, snapshot) {
                  final code = snapshot.data?.trim() ?? '';
                  return PrimaryAppBarAction(
                    icon: Icons.person,
                    label: code.isEmpty ? '-' : code,
                  );
                },
              ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _MenuMetrics.fromWidth(constraints.maxWidth);
            final cardWidth = constraints.maxWidth >= 840
                ? (constraints.maxWidth - metrics.pagePadding * 2 - 18) / 2
                : double.infinity;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      metrics.pagePadding,
                      metrics.topGap,
                      metrics.pagePadding,
                      metrics.pagePadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          children: [
                            Wrap(
                              runSpacing: metrics.cardGap,
                              spacing: 18,
                              children: [
                                for (final item in _visibleItems)
                                  SizedBox(
                                    width: cardWidth,
                                    child: MainMenuCard(
                                      title: item.labelBuilder(localizations),
                                      icon: item.icon,
                                      onTap: () => _handleMenuTap(
                                        context,
                                        item.action,
                                        item.labelBuilder(localizations),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // SizedBox(height: metrics.logoutGap),
                            // SizedBox(
                            //   width: double.infinity,
                            //   height: 56,
                            //   child: OutlinedButton.icon(
                            //     onPressed: () => Navigator.of(
                            //       context,
                            //     ).pushReplacementNamed(AppRouter.signIn),
                            //     icon: const Icon(Icons.arrow_back_rounded),
                            //     label: Text(localizations.logout),
                            //     style: OutlinedButton.styleFrom(
                            //       foregroundColor: isDark
                            //           ? colorScheme.onSurface
                            //           : Colors.black,
                            //       side: BorderSide(
                            //         color: colorScheme.primary.withValues(
                            //           alpha: 0.65,
                            //         ),
                            //       ),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //       textStyle: Theme.of(context).textTheme.titleSmall
                            //           ?.copyWith(
                            //             fontWeight: FontWeight.w800,
                            //             letterSpacing: 0,
                            //           ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: metrics.pagePadding,
                  ),
                  child: Image.asset(
                    'assets/images/branding/jaroc_logo.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleMenuTap(
    BuildContext context,
    MainMenuAction action,
    String title,
  ) {
    if (action == MainMenuAction.initialSettings) {
      Navigator.of(context).pushNamed(AppRouter.settings);
      return;
    }

    if (action == MainMenuAction.receiving) {
      Navigator.of(context).pushNamed(AppRouter.receivingSelection);
      return;
    }

    if (action == MainMenuAction.shipping) {
      Navigator.of(context).pushNamed(AppRouter.shippingSelection);
      return;
    }

    if (action == MainMenuAction.shelfPlacement) {
      Navigator.of(context).pushNamed(AppRouter.stockingSelection);
      return;
    }

    if (action == MainMenuAction.stocktaking) {
      Navigator.of(context).pushNamed(AppRouter.inventorySelection);
      return;
    }

    if (action == MainMenuAction.savedFiles) {
      Navigator.of(context).pushNamed(AppRouter.savedFiles);
      return;
    }

    Navigator.of(context).pushNamed(
      AppRouter.liveScanner,
      arguments: ScannerOption(
        key: action.name,
        title: title,
        subtitle: title,
        formats: _scannerFormats,
        colorValue: 0xFF005F73,
      ),
    );
  }

  static const List<ScannerFormat> _scannerFormats = [
    ScannerFormat.qrCode,
    ScannerFormat.code128,
    ScannerFormat.code39,
    ScannerFormat.code93,
    ScannerFormat.codabar,
    ScannerFormat.dataMatrix,
    ScannerFormat.ean13,
    ScannerFormat.ean8,
    ScannerFormat.itf2of5,
    ScannerFormat.itf14,
    ScannerFormat.pdf417,
    ScannerFormat.upcA,
    ScannerFormat.upcE,
    ScannerFormat.aztec,
  ];
}

class _MenuMetrics {
  const _MenuMetrics({
    required this.pagePadding,
    required this.topGap,
    required this.cardGap,
    required this.logoutGap,
  });

  final double pagePadding;
  final double topGap;
  final double cardGap;
  final double logoutGap;

  factory _MenuMetrics.fromWidth(double width) {
    if (width >= 720) {
      return const _MenuMetrics(
        pagePadding: 32,
        topGap: 48,
        cardGap: 18,
        logoutGap: 36,
      );
    }

    return const _MenuMetrics(
      pagePadding: 28,
      topGap: 42,
      cardGap: 16,
      logoutGap: 36,
    );
  }
}
