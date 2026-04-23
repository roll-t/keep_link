import 'package:get/get.dart';
import 'package:keep_link/core/routes/not_found/not_found_page.dart';
import 'package:keep_link/features/category/application/di/category_binding.dart';
import 'package:keep_link/features/friend/application/di/friend_binding.dart';
import 'package:keep_link/features/friend/application/di/shared_category_binding.dart';
import 'package:keep_link/features/friend/presentation/page/friend_page.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/link/module/link_add/di/add_link_binding.dart';
import 'package:keep_link/features/link/module/link_add/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/module/link_colections/di/link_collection_binding.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/page/link_collection_page.dart';
import 'package:keep_link/features/link/module/link_search/di/search_link_binding.dart';
import 'package:keep_link/features/link/module/link_search/presentation/page/search_link_page.dart';
import 'package:keep_link/features/personal/di/personal_binding.dart';
import 'package:keep_link/features/personal/presentation/page/personal_page.dart';
import 'package:keep_link/features/personal/presentation/page/privacy_policy_page.dart';
import 'package:keep_link/features/personal/presentation/page/terms_page.dart';
import 'package:keep_link/features/security/application/di/pin_verify_binding.dart';
import 'package:keep_link/features/security/application/di/security_method_binding.dart';
import 'package:keep_link/features/security/presentation/page/pin_verify_page.dart';
import 'package:keep_link/features/security/presentation/page/security_method_page.dart';
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
    name: SecurityMethodPage.routeName,
    transition: Transition.leftToRight,
    page: () => const SecurityMethodPage(),
    binding: SecurityMethodBinding(),
  ),
  GetPage(
    name: PinVerifyPage.routeName,
    transition: Transition.downToUp,
    page: () => const PinVerifyPage(),
    binding: PinVerifyBinding(),
  ),
  GetPage(
    name: SearchLinkPage.routeName,
    transition: Transition.downToUp,
    page: () => const SearchLinkPage(),
    binding: SearchLinkBinding(),
  ),
  GetPage(
    name: PersonalPage.routeName,
    transition: Transition.rightToLeft,
    page: () => const PersonalPage(),
    binding: PersonalBinding(),
  ),
  GetPage(
    name: FriendPage.routeName,
    transition: Transition.rightToLeft,
    page: () => const FriendPage(),
    binding: FriendBinding(),
  ),
  GetPage(
    name: SharedCategoriesPage.routeName,
    transition: Transition.rightToLeft,
    page: () => const SharedCategoriesPage(),
    binding: SharedCategoryBinding(),
  ),
  GetPage(
    name: PrivacyPolicyPage.routeName,
    transition: Transition.rightToLeft,
    page: () => const PrivacyPolicyPage(),
  ),
  GetPage(
    name: TermsPage.routeName,
    transition: Transition.rightToLeft,
    page: () => const TermsPage(),
  ),
];
