import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/constants/app_feature_flags.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_toolbar.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

void main() {
  testWidgets('hides scanner mode when the feature flag is disabled', (
    tester,
  ) async {
    final selectedModes = <ScannerMode>[];

    await tester.pumpWidget(
      _TestApp(
        child: ScannerToolbar(
          activeMode: ScannerMode.brQr,
          enableScannerMode: AppFeatureFlags.enableScannerMode,
          onModeChanged: selectedModes.add,
          gap: 12,
          buttonHeight: 48,
          borderRadius: 8,
        ),
      ),
    );

    expect(find.text('BR/QR'), findsOneWidget);
    expect(find.text('OCR'), findsOneWidget);
    expect(find.text('Scanner'), findsNothing);
    expect(find.byType(ScannerModeButton), findsNWidgets(2));

    await tester.tap(find.text('OCR'));

    expect(selectedModes, <ScannerMode>[ScannerMode.ocr]);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );
  }
}
