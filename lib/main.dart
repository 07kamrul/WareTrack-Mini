import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waretrack_mini/app.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _ignoreMobileScannerInactiveOrientationStreamError();
  await configureDependencies();
  runApp(const WareTrackMiniApp());
}

void _ignoreMobileScannerInactiveOrientationStreamError() {
  final previousOnError = FlutterError.onError;

  FlutterError.onError = (details) {
    final exception = details.exception;
    final context = details.context?.toString() ?? '';

    if (exception is PlatformException &&
        exception.message == 'No active stream to cancel' &&
        context.contains(
          'dev.steenbakker.mobile_scanner/scanner/deviceOrientation',
        )) {
      return;
    }

    previousOnError?.call(details);
  };
}
