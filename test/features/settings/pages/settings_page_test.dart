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
  testWidgets('shows save/transfer settings and the language selector', (
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
        locale: Locale('en'),
        supportedLocales: [Locale('en'), Locale('bn')],
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

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Bangla'), findsOneWidget);
    expect(find.text('Save & Transfer'), findsOneWidget);
    expect(find.text('Save Format'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
    expect(find.text('Transfer Destination Settings'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Settings saved.'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('App Information'), findsOneWidget);
    expect(find.text('App Name'), findsOneWidget);
    expect(find.text(AppBuildConfig.apiPayloadName), findsOneWidget);
    expect(find.text('App Version'), findsOneWidget);
    expect(find.text(AppBuildConfig.appVersion), findsOneWidget);
    expect(find.text('Theme'), findsNothing);
    expect(find.text('Light'), findsNothing);
    expect(find.text('Dark'), findsNothing);
    expect(find.text('Current Theme'), findsNothing);
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
          locale: Locale('en'),
          supportedLocales: [Locale('en'), Locale('bn')],
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

      expect(find.text('Settings saved.'), findsNothing);

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Email Address',
        ),
        'receiver@example.com',
      );
      await tester.tap(find.text('Settings'));
      await tester.pump();

      expect(find.text('Settings saved.'), findsOneWidget);
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
        locale: Locale('en'),
        supportedLocales: [Locale('en'), Locale('bn')],
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

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.text('Please enter an email address.'), findsOneWidget);
    expect(find.text('Settings saved.'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(controller.settings.transfer.emailAddress, isEmpty);
    expect(find.text('Settings'), findsOneWidget);
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
