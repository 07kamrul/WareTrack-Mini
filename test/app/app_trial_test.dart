// Exercises the trial build gate end to end. AppBuildConfig.apiEnv
// is a compile-time String.fromEnvironment, so these assertions only take
// the trial branch when built for one of the "<base>Trial" environments:
//   flutter test --dart-define=API_ENV=demo440Trial test/app/app_trial_test.dart
//   flutter test --dart-define=API_ENV=jarocDevTrial test/app/app_trial_test.dart
// The gate is keyed off AppBuildConfig.isTrial, so every trial environment
// behaves identically here. Every test self-skips on a base environment, so a
// plain `flutter test` stays green.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/app.dart';
import 'package:waretrack_mini/core/api_services/auth_service.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/app_router.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/services/trial_service.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/widgets/trial_expired_page.dart';
import 'package:waretrack_mini/data/models/trial_status_model.dart';
import 'package:waretrack_mini/data/models/user_model.dart';
import 'package:waretrack_mini/features/auth/bloc/auth_bloc.dart';
import 'package:waretrack_mini/features/auth/pages/code_verification_page.dart';
import 'package:waretrack_mini/features/auth/verify_code_use_case.dart';
import 'package:waretrack_mini/features/main_menu/pages/home_page.dart';

final bool _skipNonTrialBuild = !AppBuildConfig.isTrial;

void main() {
  testWidgets(
    'first launch: code verify response with a future datachar03 opens home',
    (tester) async {
      final storage = _FakeLocalStorage(isVerified: false);
      _registerDependencies(
        storage,
        _FakeAuthService(
          verifiedUser: _verifiedUser,
          storage: storage,
          trialEndTime: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();
      expect(find.byType(CodeVerificationPage), findsOneWidget);
      // Locks in the fix for the release-build bug where trial APKs showed
      // plain "WareTrack Mini" instead of "WareTrack Mini Trial" — this must hold
      // regardless of which APP_NAME (標準/カスタマイズ1) this test run was
      // compiled with.
      expect(find.text('WareTrack Mini Trial'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '12345678');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(
        await storage.readString(kTrialEndTime),
        isNotNull,
        reason: 'a successful code verification must cache the endtime',
      );
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'first launch: code verify response with a past datachar03 shows trial '
    'expired',
    (tester) async {
      final storage = _FakeLocalStorage(isVerified: false);
      _registerDependencies(
        storage,
        _FakeAuthService(
          verifiedUser: _verifiedUser,
          storage: storage,
          trialEndTime: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '12345678');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'first launch: code verify response with no datachar03 fails closed to '
    'trial expired (never Home)',
    (tester) async {
      final storage = _FakeLocalStorage(isVerified: false);
      _registerDependencies(
        storage,
        // No trialEndTime — mirrors a response that omitted datachar03, so
        // nothing gets cached and the gate cannot confirm an active trial.
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '12345678');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'subsequent launch: previously-verified device blocks once the stored '
    'endtime has passed',
    (tester) async {
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(CodeVerificationPage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'subsequent launch: previously-verified device with a future endtime '
    'opens home',
    (tester) async {
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().add(const Duration(days: 1)),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TrialExpiredPage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'subsequent launch: previously-verified device with no cached endtime '
    'returns to home instead of re-asking for the code',
    (tester) async {
      // isVerified=true but kTrialEndTime was never cached — e.g. a
      // code-verify response that omitted datachar03. This device already
      // spent its one allowed verification, so putting the code screen back
      // up would lock the user out of a trial that has not expired: the code
      // they still have can never be accepted a second time.
      final storage = _verifiedLocalStorage();
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(CodeVerificationPage), findsNothing);
      expect(find.byType(TrialExpiredPage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'subsequent launch: a missing endtime is still bounded — the first-launch '
    'fallback window closing blocks rather than re-asking for the code',
    (tester) async {
      // Keeping a no-endtime device on Home must not become an unbounded free
      // pass. With the TrialDuration window counted from first launch already
      // behind it, this install is expired — and expiry, not the code screen,
      // is what it gets.
      final storage = _verifiedLocalStorage(
        firstLaunchDate: DateTime.now().subtract(
          TrialDuration.current.length + const Duration(minutes: 1),
        ),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(CodeVerificationPage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'subsequent launch: the Trial-prefixed app name the server echoes back is '
    "this build's own, so the verification survives the relaunch",
    (tester) async {
      // kAppName is cached from the response's datachar01 — the server's echo
      // of the `name` the request sent, which on the trial build is the
      // Trial-prefixed AppBuildConfig.apiPayloadName rather than the bare
      // APP_NAME. Mistaking that for another build's leftover cache clears the
      // verification on every relaunch and brings the code screen back.
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().add(const Duration(days: 1)),
        appName: AppBuildConfig.apiPayloadName,
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(CodeVerificationPage), findsNothing);
      expect(
        await storage.readBool(kIsVerified),
        isTrue,
        reason: 'the cached verification must not have been cleared',
      );
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'startup failure on the trial build falls closed to the one shared block '
    'screen, not a look-alike with a non-exiting button',
    (tester) async {
      final storage = _ThrowingLocalStorage();
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      // The old hand-rolled copy of this screen put a Close App label on a
      // button that only retried verification. There must be exactly one
      // close button, and it belongs to the shared screen.
      expect(find.text('Retry'), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'app resume: a user already on Home gets blocked once the trial expires '
    'mid-session',
    (tester) async {
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().add(const Duration(days: 1)),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // The user backgrounds the app while the trial is still valid.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // The trial then lapses while the app is in the background — nothing
      // updates this except a fresh code verification, so simulate the
      // stored endtime having already passed by the time we resume.
      await storage.writeString(
        kTrialEndTime,
        DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      );

      // Periodic sampling is suspended while backgrounded, so time passing
      // out here changes nothing on its own.
      await tester.pump(_recheckInterval * 3);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // Simulate the OS bringing the app back to the foreground.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'app resume: periodic sampling restarts after a background trip, so a '
    'trial that lapses later in the same session is still caught',
    (tester) async {
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().add(const Duration(days: 1)),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      // Round trip through the background with the trial still valid — this
      // is what cancels and then must re-arm the periodic timer.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // Now lapse it with the app foregrounded and untouched. Only a
      // re-armed periodic timer can catch this.
      await storage.writeString(
        kTrialEndTime,
        DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      );
      await tester.pump(_recheckInterval);
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'app left open: the periodic check blocks once the stored endtime '
    'lapses, with no resume and no relaunch',
    (tester) async {
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().add(const Duration(days: 1)),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // The trial lapses while the app just sits there on Home. Nothing is
      // backgrounded, no lifecycle event fires, and the app is never
      // relaunched — only the periodic check can catch this.
      await storage.writeString(
        kTrialEndTime,
        DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      );

      await tester.pump(_recheckInterval);
      await tester.pumpAndSettle();

      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'app left open: an active trial is never disturbed by the periodic check',
    (tester) async {
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().add(const Duration(days: 1)),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      // Several intervals of an untouched, still-valid trial must leave the
      // user exactly where they were.
      await tester.pump(_recheckInterval * 3);
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TrialExpiredPage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'a transient local-storage failure mid-session leaves the user in place '
    'rather than blocking or crashing',
    (tester) async {
      final storage = _FlakyLocalStorage(
        _verifiedLocalStorage(
          trialEndTime: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // Storage itself starts failing reads — the periodic check must not
      // evict the user or crash the app on this.
      storage.throwOnRead = true;

      await tester.pump(_recheckInterval);
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TrialExpiredPage), findsNothing);
    },
    skip: _skipNonTrialBuild,
  );

  testWidgets(
    'once blocked the gate is one-way: back navigation cannot re-enter the '
    'app and later ticks do not stack another screen',
    (tester) async {
      final storage = _verifiedLocalStorage(
        trialEndTime: DateTime.now().add(const Duration(days: 1)),
      );
      _registerDependencies(
        storage,
        _FakeAuthService(verifiedUser: _verifiedUser, storage: storage),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(const WareTrackMiniApp());
      await tester.pumpAndSettle();

      await storage.writeString(
        kTrialEndTime,
        DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      );
      await tester.pump(_recheckInterval);
      await tester.pumpAndSettle();
      expect(find.byType(TrialExpiredPage), findsOneWidget);

      // The whole stack was replaced, so there is nothing underneath to pop
      // back to, and the screen itself refuses the pop.
      await AppRouter.navigatorKey.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(TrialExpiredPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      // Further intervals must not push duplicate block screens on top.
      await tester.pump(_recheckInterval * 3);
      await tester.pumpAndSettle();
      expect(find.byType(TrialExpiredPage), findsOneWidget);
    },
    skip: _skipNonTrialBuild,
  );
}

/// Mirrors the in-app recheck cadence. Kept slightly longer so a `pump` of
/// this length is always past the tick rather than exactly on it.
const Duration _recheckInterval = Duration(minutes: 1, seconds: 1);

/// Storage for a device that has already been through code verification.
///
/// [firstLaunchDate] pre-stamps what TrialService would otherwise set on its
/// first read, so a test can place this install before or after the
/// [TrialDuration] fallback window. [appName] overrides the cached
/// `datachar01` echo, which the trial build receives Trial-prefixed.
_FakeLocalStorage _verifiedLocalStorage({
  DateTime? trialEndTime,
  DateTime? firstLaunchDate,
  String? appName,
}) {
  return _FakeLocalStorage(
    isVerified: true,
    values: {
      kApiEnv: BaseApi.apiEnv,
      kAccesscode: '12345678',
      kDeviceUuid: 'android-device-id',
      kAppName: appName ?? AppBuildConfig.appName,
      kAppVersion: AppBuildConfig.appVersion,
      if (trialEndTime != null) kTrialEndTime: trialEndTime.toIso8601String(),
      if (firstLaunchDate != null)
        kTrialFirstLaunchDate: firstLaunchDate.toIso8601String(),
    },
  );
}

void _registerDependencies(LocalStorage storage, AuthService authService) {
  final settingsRepository = AppSettingsRepository(storage);
  final controller = AppSettingsController(
    repository: settingsRepository,
    initialSettings: const AppSettings(),
  );
  sl.registerSingleton<LocalStorage>(storage);
  sl.registerSingleton<AppSettingsController>(controller);
  sl.registerSingleton<TrialService>(TrialService(storage));
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(VerifyCodeUseCase(authService), storage),
  );
}

final class _FakeAuthService implements AuthService {
  _FakeAuthService({
    required this.verifiedUser,
    required this.storage,
    this.trialEndTime,
  });

  final UserModel verifiedUser;
  final LocalStorage storage;

  /// The endtime a successful [codeVerify] should persist as
  /// [kTrialEndTime], mirroring what AuthServiceImpl caches from the real
  /// API's `datachar03`. Null simulates a response that omitted the field.
  final DateTime? trialEndTime;

  @override
  Future<UserModel> codeVerify(String code) async {
    final endTime = trialEndTime;
    if (endTime != null) {
      await storage.writeString(kTrialEndTime, endTime.toIso8601String());
    }
    return verifiedUser;
  }

  // Not used by the current trial-gating design — TrialService now decides
  // expiration purely from the locally-cached kTrialEndTime, never from a
  // device-verify round trip. Kept only to satisfy the AuthService contract.
  @override
  Future<TrialStatusModel> verifyDeviceTrial() => throw UnimplementedError();
}

final class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage({Map<String, String>? values, bool? isVerified})
    : _values = values ?? <String, String>{},
      _isVerified = isVerified;

  final Map<String, String> _values;
  bool? _isVerified;

  @override
  Future<bool?> readBool(String key) async {
    if (key == kIsVerified) return _isVerified;
    return null;
  }

  @override
  Future<String?> readString(String key) async => _values[key];

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
    if (key == kIsVerified) _isVerified = value;
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

/// Storage that cannot answer at all, so resolving the startup state fails
/// outright rather than returning a verified/unverified answer.
final class _ThrowingLocalStorage implements LocalStorage {
  @override
  Future<bool?> readBool(String key) async => throw Exception('storage down');

  @override
  Future<String?> readString(String key) async =>
      throw Exception('storage down');

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeBool(String key, bool value) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}

/// Wraps another [LocalStorage] but can be switched, mid-test, to throw on
/// every [readString] — exercises the defensive catch around
/// TrialService.resolveTrialStatus in the periodic recheck, without
/// requiring a network call to fail (there no longer is one).
final class _FlakyLocalStorage implements LocalStorage {
  _FlakyLocalStorage(this._delegate);

  final LocalStorage _delegate;
  bool throwOnRead = false;

  @override
  Future<bool?> readBool(String key) => _delegate.readBool(key);

  @override
  Future<String?> readString(String key) async {
    if (throwOnRead) throw Exception('storage read failed');
    return _delegate.readString(key);
  }

  @override
  Future<void> remove(String key) => _delegate.remove(key);

  @override
  Future<void> writeBool(String key, bool value) =>
      _delegate.writeBool(key, value);

  @override
  Future<void> writeString(String key, String value) =>
      _delegate.writeString(key, value);
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
