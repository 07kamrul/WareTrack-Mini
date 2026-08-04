import 'package:waretrack_mini/core/constants/app_routes.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/features/auth/pages/sign_in_page.dart';
import 'package:waretrack_mini/features/auth/pages/sign_up_page.dart';
import 'package:waretrack_mini/features/inventory/pages/inventory_selection_page.dart';
import 'package:waretrack_mini/features/main_menu/pages/home_page.dart';
import 'package:waretrack_mini/features/receiving/pages/product_scan_page.dart';
import 'package:waretrack_mini/features/main_menu/widgets/menu_item.dart';
import 'package:waretrack_mini/features/receiving/pages/receiving_selection_page.dart';
import 'package:waretrack_mini/features/saved_files/pages/saved_files_page.dart';
import 'package:waretrack_mini/features/settings/pages/settings_page.dart';
import 'package:waretrack_mini/features/shipping/pages/shipping_selection_page.dart';
import 'package:waretrack_mini/features/stocking/pages/stocking_selection_page.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final RouteObserver<ModalRoute<dynamic>> routeObserver =
      RouteObserver<ModalRoute<dynamic>>();

  static const String signIn = 'signIn';
  static const String signUp = 'signUp';
  static const String home = AppRoutes.home;
  static const String liveScanner = AppRoutes.liveScanner;
  static const String receivingSelection = AppRoutes.receivingSelection;
  static const String shippingSelection = AppRoutes.shippingSelection;
  static const String stockingSelection = AppRoutes.stockingSelection;
  static const String inventorySelection = AppRoutes.inventorySelection;
  static const String savedFiles = AppRoutes.savedFiles;
  static const String savedFilesList = AppRoutes.savedFilesList;
  static const String settings = AppRoutes.settings;
  static const String profile = AppRoutes.profile;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInPage());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case liveScanner:
        final scannerOption = settings.arguments is ScannerOption
            ? settings.arguments! as ScannerOption
            : _defaultScannerOption;
        return MaterialPageRoute(
          builder: (_) => LiveScannerPage(scannerOption: scannerOption),
        );
      case receivingSelection:
        return MaterialPageRoute(
          builder: (_) => const ReceivingSelectionPage(),
        );
      case shippingSelection:
        return MaterialPageRoute(builder: (_) => const ShippingSelectionPage());
      case stockingSelection:
        return MaterialPageRoute(builder: (_) => const StockingSelectionPage());
      case inventorySelection:
        return MaterialPageRoute(
          builder: (_) => const InventorySelectionPage(),
        );
      case savedFiles:
        return MaterialPageRoute(
          builder: (_) => const SavedFilesPage(
            arguments: SavedFilesArguments(action: MainMenuAction.savedFiles),
          ),
        );
      case savedFilesList:
        final arguments = settings.arguments is SavedFilesArguments
            ? settings.arguments! as SavedFilesArguments
            : const SavedFilesArguments(action: MainMenuAction.receiving);
        return MaterialPageRoute(
          builder: (_) => SavedFilesPage(arguments: arguments),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const SignInPage());
    }
  }

  static const ScannerOption _defaultScannerOption = ScannerOption(
    key: 'barcode',
    title: 'BR/QR Scanner',
    subtitle: 'Scan QR, CODE-128, EAN, UPC, and other barcodes.',
    formats: [
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
    ],
    colorValue: 0xFF005F73,
  );
}
