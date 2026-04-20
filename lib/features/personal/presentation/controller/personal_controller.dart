import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/service/firebase_service.dart';

class PersonalController extends GetxController {
  final user = Rxn<User>();
  final isLoading = false.obs;
  StreamSubscription<User?>? _authSub;

  @override
  void onInit() {
    super.onInit();
    user.value = FirebaseService.currentUser;
    _authSub = FirebaseService.authStateChanges.listen((u) {
      user.value = u;
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  Future<void> signInWithGoogle() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await FirebaseService.signInWithGoogle();
      if (result == null) {
        Get.snackbar('Login', 'Google sign-in was cancelled');
      } else {
        Get.snackbar('Login', 'Signed in successfully');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await FirebaseService.signOut();
      Get.snackbar('Logout', 'Signed out successfully');
    } finally {
      isLoading.value = false;
    }
  }
}
