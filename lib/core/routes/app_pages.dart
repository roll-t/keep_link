import 'package:get/get.dart';
import 'package:keep_link/core/routes/not_found/not_found_page.dart';
import 'package:keep_link/features/link/application/di/link_collection_binding.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/presentation/page/link_collection_page.dart';
import 'package:keep_link/features/splash/di/splash_binding.dart';
import 'package:keep_link/features/splash/presentation/page/splash_page.dart';

final notFoundPage = GetPage(name: "/not_found", page: () => const NotFoundPage());

final appPage = [
  GetPage(name: SplashPage.routeName, page: () => const SplashPage(), binding: SplashBinding()),
  GetPage(
    name: LinkCollectionPage.routeName,
    page: () => const LinkCollectionPage(),
    binding: LinkCollectionBinding(),
  ),
  GetPage(
    name: AddLinkPage.routeName,
    page: () => const AddLinkPage(),
    transition: Transition.downToUp,
  ),
];
