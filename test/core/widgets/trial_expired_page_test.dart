import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/trial_expired_page.dart';

void main() {
  MaterialApp buildLocalizedApp({
    required Widget home,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: home,
    );
  }

  testWidgets('shows the localized trial expiry message', (tester) async {
    await tester.pumpWidget(buildLocalizedApp(home: const TrialExpiredPage()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TrialExpiredPage));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.trialExpiredMessageJa), findsOneWidget);
  });

  testWidgets('tapping the close button invokes the close callback', (
    tester,
  ) async {
    var closeCount = 0;
    await tester.pumpWidget(
      buildLocalizedApp(home: TrialExpiredPage(onClose: () => closeCount++)),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TrialExpiredPage));
    await tester.tap(find.text(AppLocalizations.of(context).closeAppButton));
    await tester.pumpAndSettle();

    expect(closeCount, 1);
  });

  testWidgets('by default the close button asks the platform to exit the app', (
    tester,
  ) async {
    // The injected-callback test above proves the button is wired to
    // _onClose; this one proves the *default* _onClose actually terminates
    // the process rather than popping a route or backgrounding the app.
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(buildLocalizedApp(home: const TrialExpiredPage()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TrialExpiredPage));
    await tester.tap(find.text(AppLocalizations.of(context).closeAppButton));
    await tester.pumpAndSettle();

    expect(
      platformCalls.map((call) => call.method),
      contains('SystemNavigator.pop'),
    );
  });

  testWidgets('blocks the back navigation gesture', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      buildLocalizedApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('behind')),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const TrialExpiredPage()),
    );
    await tester.pumpAndSettle();

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(TrialExpiredPage), findsOneWidget);
  });
}
