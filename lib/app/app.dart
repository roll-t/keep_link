import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/app/app_binding.dart';
import 'package:keep_link/core/config/theme/app_theme.dart';
import 'package:keep_link/core/localization/theme_translations.dart';
import 'package:keep_link/core/localization/translation_service.dart';
import 'package:keep_link/core/routes/app_pages.dart';
import 'package:keep_link/core/config/theme/theme_service.dart';
import 'package:keep_link/features/splash/presentation/page/splash_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      ThemeMode themeMode = _getThemeMode();
      return GetMaterialApp(
        defaultTransition: Transition.noTransition,
        debugShowCheckedModeBanner: false,
        transitionDuration: const Duration(milliseconds: 150),
        builder: FToastBuilder(),

        ///---> [Localization service]
        translations: LocalizationService(),
        locale: LocalizationService.locale,
        fallbackLocale: LocalizationService.fallbackLocale,
        supportedLocales: LocalizationService.locales,
        localizationsDelegates: LocalizationService.delegates,

        ///---> [Page config]
        getPages: appPage,
        initialRoute: SplashPage.routeName,
        initialBinding: AppBinding(),
        home: const SplashPage(),
        unknownRoute: notFoundPage,

        ///---> [Theme config]
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
      );
    });
  }

  ThemeMode _getThemeMode() {
    final mode = ThemeService.themeMode;
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}
