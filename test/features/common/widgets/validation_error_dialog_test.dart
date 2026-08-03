import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/widgets/validation_error_dialog.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

void main() {
  testWidgets('duplicate validation calls show one dialog closed by one tap', (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp());

    await tester.tap(find.text('Show validation'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Show validation'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () {
                showValidationErrorDialog(context, 'Validation failed.');
                showValidationErrorDialog(context, 'Validation failed.');
              },
              child: const Text('Show validation'),
            ),
          );
        },
      ),
    );
  }
}
