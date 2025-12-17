import 'package:get/get.dart';
import 'package:keep_link/core/routes/not_found/not_found_page.dart';
import 'package:keep_link/features/category/application/di/category_binding.dart';
import 'package:keep_link/features/link/application/di/add_link_binding.dart';
import 'package:keep_link/features/link/application/di/link_collection_binding.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/presentation/page/link_collection_page.dart';
import 'package:keep_link/features/security/application/di/pin_verify_binding.dart';
import 'package:keep_link/features/security/application/di/security_method_binding.dart';
import 'package:keep_link/features/security/presentation/page/pin_verify_page.dart';
import 'package:keep_link/features/security/presentation/page/security_method_page.dart';
import 'package:keep_link/features/setting/application/di/setting_binding.dart';
import 'package:keep_link/features/setting/application/di/warning_binding.dart';
import 'package:keep_link/features/setting/presentation/page/setting_page.dart';
import 'package:keep_link/features/setting/presentation/page/warning_page.dart';
import 'package:keep_link/features/splash/di/splash_binding.dart';
import 'package:keep_link/features/splash/presentation/page/splash_page.dart';

final notFoundPage = GetPage(name: "/not_found", page: () => const NotFoundPage());

final appPage = [
  GetPage(
    name: SplashPage.routeName,
    page: () => const SplashPage(),
    bindings: [SplashBinding(), PinVerifyBinding()],
  ),
  GetPage(
    name: LinkCollectionPage.routeName,

    page: () => const LinkCollectionPage(),
    bindings: [CategoryBinding(), LinkCollectionBinding()],
  ),
  GetPage(
    name: AddLinkPage.routeName,
    page: () => const AddLinkPage(),
    transition: Transition.downToUp,
    bindings: [AddLinkBinding(), CategoryBinding()],
  ),
  GetPage(
    name: SettingPage.routeName,
    transition: Transition.leftToRight,
    page: () => const SettingPage(),
    binding: SettingBinding(),
  ),
  GetPage(
    name: SecurityMethodPage.routeName,
    transition: Transition.leftToRight,
    page: () => const SecurityMethodPage(),
    binding: SecurityMethodBinding(),
  ),
  GetPage(
    name: WarningPage.routeName,
    transition: Transition.leftToRight,
    page: () => const WarningPage(),
    binding: WarningBinding(),
  ),
  GetPage(
    name: PinVerifyPage.routeName,
    transition: Transition.downToUp,
    page: () => const PinVerifyPage(),
    binding: PinVerifyBinding(),
  ),
];
