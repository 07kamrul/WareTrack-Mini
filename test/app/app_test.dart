import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/app.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/models/trial_status_model.dart';
import 'package:waretrack_mini/core/widgets/trial_expired_page.dart';
import 'package:waretrack_mini/data/models/user_model.dart';
import 'package:waretrack_mini/core/api_services/auth_service.dart';
// TODO: Temporarily disabled with checkDeviceVerification().
// import 'package:waretrack_mini/features/auth/check_device_verification_use_case.dart';
import 'package:waretrack_mini/features/auth/verify_code_use_case.dart';
import 'package:waretrack_mini/features/auth/bloc/auth_bloc.dart';
import 'package:waretrack_mini/features/auth/pages/code_verification_page.dart';
import 'package:waretrack_mini/features/main_menu/pages/home_page.dart';
import 'package:waretrack_mini/features/settings/bloc/settings_bloc.dart';
import 'package:waretrack_mini/features/settings/pages/settings_page.dart';

void main() {
  testWidgets('always uses light theme when the device uses dark mode', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final storage = _verifiedLocalStorage();
    _registerDependencies(storage, _FakeAuthService(_verifiedUser));
    addTearDown(sl.reset);

    await tester.pumpWidget(const WareTrackMiniApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.light);
  });

  testWidgets(
    'locally verified device starts at home without checking server',
    (tester) async {
      final storage = _verifiedLocalStorage();
      final authService = _FakeAuthService(_verifiedUser);
      _registerDependencies(storage, authService);
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(CodeVerificationPage), findsNothing);
      expect(storage.authStatusReadCount, 1);
      expect(authService.checkCount, 0);
    },
  );

  testWidgets('main menu profile pill shows cached user number only', (
    tester,
  ) async {
    final storage = _verifiedLocalStorage(values: {kCode: '1'});
    _registerDependencies(storage, _FakeAuthService(_verifiedUser));
    addTearDown(sl.reset);

    await tester.pumpWidget(const WareTrackMiniApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets(
    'non-trial build opens home for a verified device without any TrialService',
    (tester) async {
      // No TrialService is registered at all — this proves the shipping
      // (non-trial) build path never consults it, matching
      // AppBuildConfig.apiEnv being 'demo440' — a base environment, so
      // AppBuildConfig.isTrial is false — during this test.
      final storage = _verifiedLocalStorage();
      _registerDependencies(storage, _FakeAuthService(_verifiedUser));
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TrialExpiredPage), findsNothing);
    },
  );

  testWidgets('unverified local cache opens code page', (tester) async {
    final storage = _FakeLocalStorage(isVerified: false);
    _registerDependencies(storage, _FakeAuthService(null));
    addTearDown(sl.reset);

    await tester.pumpWidget(const WareTrackMiniApp());
    await tester.pumpAndSettle();

    expect(find.byType(CodeVerificationPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(storage.authStatusReadCount, 1);
  });

  testWidgets('incomplete restored verification cache opens code page', (
    tester,
  ) async {
    final storage = _FakeLocalStorage(isVerified: true);
    _registerDependencies(storage, _FakeAuthService(null));
    addTearDown(sl.reset);

    await tester.pumpWidget(const WareTrackMiniApp());
    await tester.pumpAndSettle();

    expect(find.byType(CodeVerificationPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(storage.readString(kAccesscode), completion(isNull));
    expect(storage.readString(kDeviceUuid), completion(isNull));
    expect(storage.readBool(kIsVerified), completion(isNull));
  });

  testWidgets(
    'successful code verification opens main menu and clears verify page',
    (tester) async {
      final storage = _FakeLocalStorage(isVerified: false);
      _registerDependencies(storage, _FakeAuthService(_verifiedUser));
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(CodeVerificationPage), findsOneWidget);

      await tester.enterText(find.byType(TextField), '12345678');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(CodeVerificationPage), findsNothing);
    },
  );

  // TODO: Temporarily disabled with checkDeviceVerification().
  // testWidgets('startup verification failure retries device verification', (
  //   tester,
  // ) async {
  //   final storage = _FakeLocalStorage(isVerified: false);
  //   final authService = _RetryAuthService();
  //   _registerDependencies(storage, authService);
  //   addTearDown(sl.reset);
  //
  //   await tester.pumpWidget(const WareTrackMiniApp());
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(HomePage), findsNothing);
  //   expect(find.byType(CodeVerificationPage), findsNothing);
  //   expect(authService.checkCount, 1);
  //
  //   await tester.tap(find.byType(FilledButton));
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(HomePage), findsOneWidget);
  //   expect(authService.checkCount, 2);
  // });

  testWidgets('typing and dismissing keyboard keeps initial settings open', (
    tester,
  ) async {
    final storage = _verifiedLocalStorage();
    final controller = _registerDependencies(
      storage,
      _FakeAuthService(_verifiedUser),
    );
    addTearDown(sl.reset);

    await tester.pumpWidget(const WareTrackMiniApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Initial Setup'));
    await tester.tap(find.text('Initial Setup'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);

    const emailAddress = 'receiver@example.com';
    final emailField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Email Address',
    );
    await tester.scrollUntilVisible(
      emailField,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(emailField, emailAddress);
    await tester.pumpAndSettle();

    final saveEmailButton = find.widgetWithText(FilledButton, 'Settings');
    await tester.ensureVisible(saveEmailButton);
    await tester.tap(saveEmailButton);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(controller.settings.transfer.emailAddress, emailAddress);
    expect(storage.lastWrittenValue, contains(emailAddress));

    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(storage.authStatusReadCount, 1);
  });
}

_FakeLocalStorage _verifiedLocalStorage({Map<String, String>? values}) {
  return _FakeLocalStorage(
    values: {
      kApiEnv: BaseApi.apiEnv,
      kAccesscode: '12345678',
      kDeviceUuid: 'android-device-id',
      kAppName: AppBuildConfig.appName,
      kAppVersion: AppBuildConfig.appVersion,
      ...?values,
    },
    isVerified: true,
  );
}

AppSettingsController _registerDependencies(
  _FakeLocalStorage storage,
  AuthService authService,
) {
  final settingsRepository = AppSettingsRepository(storage);
  final controller = AppSettingsController(
    repository: settingsRepository,
    initialSettings: const AppSettings(),
  );
  sl.registerSingleton<LocalStorage>(storage);
  sl.registerSingleton<AppSettingsController>(controller);
  // TODO: Temporarily disabled with checkDeviceVerification().
  // sl.registerFactory<CheckDeviceVerificationUseCase>(
  //   () => CheckDeviceVerificationUseCase(authService),
  // );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(VerifyCodeUseCase(authService), storage),
  );
  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(settingsController: controller),
  );
  return controller;
}

final class _FakeAuthService implements AuthService {
  _FakeAuthService(this.verifiedUser);

  final UserModel? verifiedUser;
  int checkCount = 0;

  // TODO: Temporarily disabled with checkDeviceVerification().
  // @override
  // Future<UserModel?> checkDeviceVerification() async {
  //   checkCount++;
  //   return verifiedUser;
  // }

  @override
  Future<UserModel> codeVerify(String code) async => _verifiedUser;

  @override
  Future<TrialStatusModel> verifyDeviceTrial() => throw UnimplementedError();
}

// TODO: Temporarily disabled with checkDeviceVerification().
// final class _RetryAuthService implements AuthService {
//   int checkCount = 0;
//
//   @override
//   Future<UserModel?> checkDeviceVerification() async {
//     checkCount++;
//     if (checkCount == 1) {
//       throw Exception('startup verification failed');
//     }
//     return _verifiedUser;
//   }
//
//   @override
//   Future<UserModel> codeVerify(String code) async => _verifiedUser;
// }

final class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage({Map<String, String>? values, bool? isVerified})
    : _values = values ?? <String, String>{},
      _isVerified = isVerified;

  final Map<String, String> _values;
  bool? _isVerified;
  int authStatusReadCount = 0;
  String? lastWrittenValue;

  @override
  Future<bool?> readBool(String key) async {
    if (key == kIsVerified) {
      authStatusReadCount++;
      return _isVerified;
    }
    return null;
  }

  @override
  Future<String?> readString(String key) async {
    return _values[key];
  }

  @override
  Future<void> remove(String key) async {
    if (key == kIsVerified) {
      _isVerified = null;
      return;
    }
    _values.remove(key);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    if (key == kIsVerified) {
      _isVerified = value;
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
    lastWrittenValue = value;
  }
}

final UserModel _verifiedUser = UserModel(
  code: 1,
  companyId: 2,
  status: 1,
  kcode1: 3,
  accesscode: 12345678,
  datachar01: 'one',
  datachar02: 'two',
);
