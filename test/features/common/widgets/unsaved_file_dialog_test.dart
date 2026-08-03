import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/constants/app_theme.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/scan_confirmation_dialog.dart';
import 'package:waretrack_mini/core/widgets/unsaved_file_dialog.dart';

/// Matches a [Text] whose *visible* content equals [expected], ignoring the
/// invisible WORD JOINER characters that [DialogMessageText] inserts so popup
/// text wraps at natural clause boundaries.
Finder findVisibleText(String expected) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data?.replaceAll('⁠', '') == expected,
  );
}

void main() {
  testWidgets('shows scan save confirmation with matching action buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const _DialogLauncher(),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(findVisibleText('スキャンしたファイルを保存しますか？'), findsOneWidget);

    final noFinder = find.widgetWithText(OutlinedButton, 'いいえ');
    final yesFinder = find.widgetWithText(FilledButton, 'はい');

    expect(noFinder, findsOneWidget);
    expect(yesFinder, findsOneWidget);

    final noButton = tester.widget<OutlinedButton>(noFinder);
    final yesButton = tester.widget<FilledButton>(yesFinder);
    final noStyle = noButton.style!;
    final yesStyle = yesButton.style!;
    final colorScheme = AppTheme.light().colorScheme;

    expect(noStyle.backgroundColor?.resolve({}), Colors.white);
    expect(noStyle.foregroundColor?.resolve({}), colorScheme.primary);
    expect(noStyle.side?.resolve({})?.color, colorScheme.primary);
    expect(noStyle.textStyle?.resolve({})?.fontWeight, FontWeight.w700);
    expect(yesStyle.backgroundColor?.resolve({}), colorScheme.primary);
    expect(yesStyle.foregroundColor?.resolve({}), Colors.white);
    expect(yesStyle.textStyle?.resolve({})?.fontWeight, FontWeight.w700);

    expect(tester.getSize(noFinder), tester.getSize(yesFinder));
    expect(tester.getTopLeft(noFinder).dy, tester.getTopLeft(yesFinder).dy);
  });

  testWidgets('delete confirmation uses beige and red button colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const _DeleteDialogLauncher(),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(findVisibleText('選択した行を削除します。よろしいですか？'), findsOneWidget);

    final noFinder = find.widgetWithText(FilledButton, 'いいえ');
    final yesFinder = find.widgetWithText(FilledButton, 'はい');
    final noStyle = tester.widget<FilledButton>(noFinder).style!;
    final yesStyle = tester.widget<FilledButton>(yesFinder).style!;

    expect(noStyle.backgroundColor?.resolve({}), const Color(0xFFF1D4B3));
    expect(noStyle.foregroundColor?.resolve({}), Colors.black);
    expect(yesStyle.backgroundColor?.resolve({}), Colors.red);
    expect(yesStyle.foregroundColor?.resolve({}), Colors.white);
    expect(tester.getSize(noFinder), tester.getSize(yesFinder));
  });
}

class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showUnsavedFileConfirmationDialog(context),
          child: const Text('open'),
        ),
      ),
    );
  }
}

class _DeleteDialogLauncher extends StatelessWidget {
  const _DeleteDialogLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showScanConfirmationDialog(
            context,
            message: '選択した行を削除します。よろしいですか？',
            messageStyle: const TextStyle(color: Colors.red),
            cancelBackgroundColor: const Color(0xFFF1D4B3),
            cancelForegroundColor: Colors.black,
            confirmBackgroundColor: Colors.red,
            confirmForegroundColor: Colors.white,
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}
