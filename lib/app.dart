import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/app_router.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/app_settings_scope.dart';
import 'package:waretrack_mini/core/constants/app_theme.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/auth/pages/sign_in_page.dart';

class WareTrackMiniApp extends StatefulWidget {
  const WareTrackMiniApp({super.key});

  @override
  State<WareTrackMiniApp> createState() => _WareTrackMiniAppState();
}

class _WareTrackMiniAppState extends State<WareTrackMiniApp> {
  @override
  Widget build(BuildContext context) {
    final settingsController = sl<AppSettingsController>();

    return AppSettingsScope(
      controller: settingsController,
      child: AnimatedBuilder(
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
            home: const SignInPage(),
            navigatorKey: AppRouter.navigatorKey,
            navigatorObservers: [AppRouter.routeObserver],
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
