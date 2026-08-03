import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/features/settings/bloc/settings_bloc.dart';
import 'package:waretrack_mini/features/settings/pages/settings_page.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

void main() {
  testWidgets('shows only Japanese save and transfer settings', (tester) async {
    final storage = _FakeLocalStorage();
    final repository = AppSettingsRepository(storage);
    final controller = AppSettingsController(
      repository: repository,
      initialSettings: const AppSettings(),
    );
    sl.registerFactory<SettingsBloc>(
      () => SettingsBloc(settingsController: controller),
    );
    addTearDown(sl.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        supportedLocales: [Locale('ja')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('保存・送信'), findsOneWidget);
    expect(find.text('保存形式'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
    expect(find.text('送信先設定'), findsOneWidget);
    expect(find.text('メールアドレス'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('保存'), findsNothing);
    expect(find.text('メールアドレス設定完了しました。'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('アプリ情報'), findsOneWidget);
    expect(find.text('アプリ名'), findsOneWidget);
    expect(find.text(AppBuildConfig.apiPayloadName), findsOneWidget);
    expect(find.text('アプリバージョン'), findsOneWidget);
    expect(find.text(AppBuildConfig.appVersion), findsOneWidget);
    expect(find.text('言語'), findsNothing);
    expect(find.text('日本語'), findsNothing);
    expect(find.text('英語'), findsNothing);
    expect(find.text('テーマ'), findsNothing);
    expect(find.text('ライト'), findsNothing);
    expect(find.text('ダーク'), findsNothing);
    expect(find.text('現在のテーマ'), findsNothing);

    // The Trial build hides the 承認コード確認 card entirely — Standard
    // keeps it, including the confirm flow below.
    if (AppBuildConfig.isTrial) {
      expect(find.text('承認コード確認'), findsNothing);
      expect(find.text('承認コード'), findsNothing);
      return;
    }

    expect(find.text('承認コード確認'), findsOneWidget);
    expect(find.text('承認コード'), findsOneWidget);
    expect(find.text('確認'), findsOneWidget);

    await tester.ensureVisible(find.text('確認'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認'));
    await tester.pump();

    expect(find.text('承認コードを入力してください。'), findsOneWidget);
  });

  testWidgets(
    'shows mail save success inline after setting button is pressed',
    (tester) async {
      final storage = _FakeLocalStorage();
      final repository = AppSettingsRepository(storage);
      final controller = AppSettingsController(
        repository: repository,
        initialSettings: const AppSettings(),
      );
      sl.registerFactory<SettingsBloc>(
        () => SettingsBloc(settingsController: controller),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ja'),
          supportedLocales: [Locale('ja')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('メールアドレス設定完了しました。'), findsNothing);

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'メールアドレス',
        ),
        'receiver@example.com',
      );
      await tester.tap(find.text('設定'));
      await tester.pump();

      expect(find.text('メールアドレス設定完了しました。'), findsOneWidget);
      expect(find.text('設定を保存しました'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(controller.settings.transfer.emailAddress, 'receiver@example.com');
    },
  );

  testWidgets('shows required message and does not save when email is empty', (
    tester,
  ) async {
    final storage = _FakeLocalStorage();
    final repository = AppSettingsRepository(storage);
    final controller = AppSettingsController(
      repository: repository,
      initialSettings: const AppSettings(),
    );
    sl.registerFactory<SettingsBloc>(
      () => SettingsBloc(settingsController: controller),
    );
    addTearDown(sl.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        supportedLocales: [Locale('ja')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('設定'));
    await tester.pump();

    expect(find.text('メールアドレスを入力してください。'), findsOneWidget);
    expect(find.text('メールアドレス設定完了しました。'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(controller.settings.transfer.emailAddress, isEmpty);
    expect(find.text('設定'), findsOneWidget);
  });
}

final class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage([Map<String, String>? values]) : _values = values ?? {};

  final Map<String, String> _values;

  @override
  Future<bool?> readBool(String key) async => null;

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeBool(String key, bool value) async {}

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
