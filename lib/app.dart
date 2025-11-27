import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/app_binding.dart';
import 'package:keep_link/core/lang/translation_service.dart';
import 'package:keep_link/core/routes/app_pages.dart';
import 'package:keep_link/features/splash/presentation/page/splash_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return  GetMaterialApp(
          debugShowCheckedModeBanner: false,

          ///---> [Localization service]
          translations: LocalizationService(),
          locale: LocalizationService.locale,
          fallbackLocale: LocalizationService.fallbackLocale,
          supportedLocales: LocalizationService.locales,
          localizationsDelegates: LocalizationService.delegates,
          ///---> [Page config]
          getPages: appPage,
          initialRoute: "/splash",
          initialBinding: AppBinding(),
          home: const SplashPage(),
          unknownRoute: notFoundPage,

          ///---> [Theme config]
          // theme: AppTheme.light(colorScheme),
          // darkTheme: AppTheme.dark(colorScheme),
          // themeMode: themeController.themeMode.value,
        );
  }
}
