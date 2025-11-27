import 'package:get/get.dart';
import 'package:keep_link/core/routes/not_found/not_found_page.dart';
import 'package:keep_link/features/splash/presentation/page/splash_page.dart';

final notFoundPage = GetPage(
  name: "/not_found",
  page: () => const NotFoundPage(),
);

final appPage = [
  GetPage(
    name: SplashPage.routeName,
    page: () => const SplashPage(),
    bindings: [],
  ),
];
