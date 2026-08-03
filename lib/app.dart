import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/app_router.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/services/trial_service.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/app_settings_scope.dart';
import 'package:waretrack_mini/core/constants/app_theme.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/trial_expired_page.dart';
import 'package:waretrack_mini/features/auth/pages/code_verification_page.dart';
import 'package:waretrack_mini/features/main_menu/pages/home_page.dart';

enum _StartupState { trialExpired, verified, unverified }

class WareTrackMiniApp extends StatefulWidget {
  const WareTrackMiniApp({super.key});

  @override
  State<WareTrackMiniApp> createState() => _WareTrackMiniAppState();
}

/// How often the trial build re-checks the gate while the app is sitting
/// open in the foreground.
///
/// This is only the sampling rate of the check — the trial's endtime itself
/// is whatever was last cached from the server (see TrialService). It
/// exists so a session that was opened *before* the trial lapsed and is
/// simply left running across the boundary is caught within a minute,
/// instead of surviving until the next resume or cold start.
const Duration _trialRecheckInterval = Duration(minutes: 1);

class _WareTrackMiniAppState extends State<WareTrackMiniApp>
    with WidgetsBindingObserver {
  late Future<_StartupState> _startupState;

  /// Drives the "app is open right now" arm of the gate. Only ever non-null
  /// on the trial build, and only while the app is foregrounded.
  Timer? _trialRecheckTimer;

  /// Guards against a slow check overlapping the next tick.
  bool _trialCheckInFlight = false;

  /// Set once the block screen is up. The gate is one-way: nothing after
  /// this point may re-check, re-navigate, or otherwise let the user back in.
  bool _trialBlocked = false;

  static bool get _isTrialBuild => AppBuildConfig.isTrial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startupState = _resolveStartupState();
  }

  @override
  void dispose() {
    _stopTrialWatch();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isTrialBuild) return;

    if (state == AppLifecycleState.resumed) {
      // Two things on the way back to the foreground: check immediately (the
      // trial may well have lapsed while backgrounded), and resume the
      // periodic sampling that was stopped on the way out.
      unawaited(_recheckTrialGate());
      _startTrialWatch();
      return;
    }

    // Backgrounded, hidden, or detached — nothing to police until we're
    // visible again, and polling the server from the background is waste.
    _stopTrialWatch();
  }

  /// Starts periodic re-checks while the trial build is open. Safe to call
  /// repeatedly; the previous timer is always replaced rather than stacked.
  void _startTrialWatch() {
    if (!_isTrialBuild || _trialBlocked) return;
    // Startup resolution is async, so this can be reached after the state was
    // torn down — starting a timer then would outlive `dispose`.
    if (!mounted) return;

    _trialRecheckTimer?.cancel();
    _trialRecheckTimer = Timer.periodic(
      _trialRecheckInterval,
      (_) => unawaited(_recheckTrialGate()),
    );
  }

  void _stopTrialWatch() {
    _trialRecheckTimer?.cancel();
    _trialRecheckTimer = null;
  }

  /// Re-validates the trial gate for the trial build, so a user already past
  /// the initial gate — on the main menu, or mid-way through any feature
  /// screen — is forced out the moment the trial lapses, rather than only at
  /// the next cold start. Called on resume and on every
  /// [_trialRecheckInterval] tick.
  ///
  /// A no-op on every other API environment, and a no-op while the trial is
  /// still active, so it never disturbs normal in-app navigation.
  Future<void> _recheckTrialGate() async {
    if (!_isTrialBuild || _trialBlocked || _trialCheckInFlight) return;

    _trialCheckInFlight = true;
    try {
      final result = await sl<TrialService>().resolveTrialStatus();
      // Only a definite `expired` blocks. `unknown` means no endtime has
      // ever been cached for this device — evicting an already-working user
      // on that would punish missing/stale local data rather than an actual
      // expiry.
      if (result != TrialGateResult.expired) return;
      if (!mounted) return;
      _blockOnTrialExpiry();
    } on Exception {
      // TrialService.resolveTrialStatus is a pure local comparison and does
      // not throw in practice, but a failure here still must not evict the
      // user; the next tick retries.
    } finally {
      _trialCheckInFlight = false;
    }
  }

  /// Replaces the entire navigation stack with the shared expiry screen.
  /// `pushAndRemoveUntil` with a false-returning predicate leaves nothing
  /// underneath, so there is no route to pop back to and no way into the app
  /// short of the screen's own close button.
  void _blockOnTrialExpiry() {
    if (_trialBlocked) return;

    final navigator = AppRouter.navigatorKey.currentState;
    // No navigator yet (still on the startup splash, for instance) — leave
    // the flag clear so the next tick tries again rather than silently
    // marking the app blocked without a block screen.
    if (navigator == null) return;

    _trialBlocked = true;
    _stopTrialWatch();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const TrialExpiredPage()),
      (route) => false,
    );
  }

  Future<_StartupState> _resolveStartupState() async {
    final isVerified = await _resolveVerificationStatus();

    // The trial gate only exists on the trial build — every other
    // environment keeps exactly the verified/unverified-only outcome and never
    // touches TrialService at all.
    if (!_isTrialBuild) {
      return isVerified ? _StartupState.verified : _StartupState.unverified;
    }

    if (!isVerified) {
      // Not through code verification yet. That page runs its own trial
      // check before letting anyone through, but the trial can just as
      // easily lapse while the user sits on it, so the watch starts here too.
      _startTrialWatch();
      return _StartupState.unverified;
    }

    final trialService = sl<TrialService>();
    final result = await trialService.resolveTrialStatus();

    if (result == TrialGateResult.expired) {
      // Already expired at cold start: the block screen is rendered directly
      // as `home`, so mark the gate closed and never start the watch.
      _trialBlocked = true;
      _stopTrialWatch();
      return _StartupState.trialExpired;
    }

    // Past the code screen once already, and the trial has not lapsed — so
    // this device goes straight back to Home. Code verification is a
    // once-per-install step: the server accepts a given device's code exactly
    // once, so re-prompting a device that already used it locks the user out
    // of a trial that is still running rather than letting them back in.
    //
    // That is why `unknown` lands here alongside `active` instead of on the
    // code screen. `unknown` only means no server endtime is cached for this
    // device — it is not a claim that the trial is over — and the window stays
    // bounded either way: resolveTrialStatus applies the TrialDuration
    // fallback from first launch, and would already have reported `expired`
    // above once that window closed. This matches how _recheckTrialGate
    // treats `unknown` mid-session.
    _startTrialWatch();
    return _StartupState.verified;
  }

  Future<bool> _resolveVerificationStatus() async {
    final storage = sl<LocalStorage>();

    // Must have an explicit verified flag before trusting any other stored data.
    final isVerified = await storage.readBool(kIsVerified);
    if (isVerified != true) return false;

    // The cached verification must have been written by an APK built for the
    // same API environment; another environment's cache is never valid here.
    final storedApiEnv = await storage.readString(kApiEnv);
    if (storedApiEnv != BaseApi.apiEnv) {
      return _rejectStaleVerification(storage);
    }

    final storedName = await storage.readString(kAppName);
    final storedVersion = await storage.readString(kAppVersion);

    if (storedName == null || storedVersion == null) {
      return _rejectStaleVerification(storage);
    }

    if (!_isThisBuildsAppName(storedName) ||
        storedVersion != AppBuildConfig.appVersion) {
      return _rejectStaleVerification(storage);
    }

    return true;
  }

  /// Whether [storedName] names *this* build, and so belongs to a verification
  /// this build can still trust.
  ///
  /// The cached value is the server's `datachar01` echo of the `name` the
  /// verification request sent, and that payload is
  /// [AppBuildConfig.apiPayloadName] — Trial-prefixed on the trial build, bare
  /// on every other one. Both spellings are accepted so the guard still
  /// catches a different build's leftover cache without rejecting this build's
  /// own echo: rejecting that would clear the verification on every relaunch
  /// and send the device back to a code screen it can only pass once.
  ///
  /// On non-trial builds [AppBuildConfig.apiPayloadName] is
  /// [AppBuildConfig.appName], so this is the same single comparison as before.
  static bool _isThisBuildsAppName(String storedName) =>
      storedName == AppBuildConfig.appName ||
      storedName == AppBuildConfig.apiPayloadName;

  /// A verified flag whose supporting data is missing or was written for a
  /// different build must never be trusted again — drop it so the device goes
  /// through code verification against this build's API environment.
  Future<bool> _rejectStaleVerification(LocalStorage storage) async {
    await storage.clearVerificationData();
    return false;
  }

  void _retryDeviceVerification() {
    setState(() {
      _startupState = _resolveStartupState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = sl<AppSettingsController>();

    return AppSettingsScope(
      controller: settingsController,
      child: FutureBuilder<_StartupState>(
        future: _startupState,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            final lightTheme = AppTheme.light();
            return MaterialApp(
              themeMode: ThemeMode.light,
              theme: lightTheme,
              darkTheme: lightTheme,
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            final lightTheme = AppTheme.light();
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: settingsController.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              themeMode: ThemeMode.light,
              theme: lightTheme,
              darkTheme: lightTheme,
              // The trial build fails closed: if the gate could not be
              // resolved at all, the user does not get in. That is the same
              // outcome as an expiry, so it reuses the one shared block
              // screen rather than hand-rolling a look-alike — which is how
              // this branch previously ended up with a Close App button
              // that only retried verification instead of exiting.
              home: _isTrialBuild
                  ? const TrialExpiredPage()
                  : Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context).trialExpiredMessage),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _retryDeviceVerification,
                              child: Text(
                                AppLocalizations.of(context).closeAppButton,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          }

          final startupState = snapshot.data ?? _StartupState.unverified;
          return AnimatedBuilder(
            animation: settingsController,
            builder: (context, _) {
              final lightTheme = AppTheme.light();
              return MaterialApp(
                onGenerateTitle: (context) => AppBuildConfig.displayName(
                  AppLocalizations.of(context).appTitle,
                ),
                debugShowCheckedModeBanner: false,
                locale: settingsController.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                themeMode: ThemeMode.light,
                theme: lightTheme,
                darkTheme: lightTheme,
                home: switch (startupState) {
                  _StartupState.trialExpired => const TrialExpiredPage(),
                  _StartupState.verified => const HomePage(),
                  _StartupState.unverified => const CodeVerificationPage(),
                },
                navigatorKey: AppRouter.navigatorKey,
                navigatorObservers: [AppRouter.routeObserver],
                onGenerateRoute: AppRouter.onGenerateRoute,
              );
            },
          );
        },
      ),
    );
  }
}
