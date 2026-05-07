import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/cache/app_get_storage.dart';
import 'package:keep_link/core/cache/sql_lite.dart';
import 'package:keep_link/core/service/firebase_service.dart';
import 'package:keep_link/core/service/friend_connection_service.dart';
import 'package:keep_link/core/service/image_kit_service.dart';
import 'package:keep_link/core/service/session_sync_service.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/personal/di/feedback_binding.dart';
import 'package:keep_link/features/personal/presentation/controller/feedback_controller.dart';
import 'package:keep_link/features/personal/presentation/page/feedback_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PersonalController extends GetxController {
  final user = Rxn<User>();
  final isLoading = false.obs;
  final isUploadingAvatar = false.obs;
  final appVersion = ''.obs;
  StreamSubscription<User?>? _authSub;

  // ── Stats (computed from reactive cache) ─────────────────────────────────

  int get totalLinks => AppCache.links.length;

  int get totalCategories => AppCache.categories.length;

  int get linksThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return AppCache.links.where((l) => l.createdAt != null && l.createdAt!.isAfter(weekAgo)).length;
  }

  int get currentStreak {
    final dates =
        AppCache.links
            .where((l) => l.createdAt != null)
            .map((l) => DateTime(l.createdAt!.year, l.createdAt!.month, l.createdAt!.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (dates.first.isBefore(todayDate.subtract(const Duration(days: 1)))) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      if (dates[i].difference(dates[i + 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String? get personalFriendLink {
    final currentUser = user.value;
    if (currentUser == null) return null;
    return FriendConnectionService.buildLink(currentUser);
  }

  @override
  void onInit() {
    super.onInit();
    user.value = FirebaseService.currentUser;
    if (user.value != null) {
      Future<void>(() => FirebaseService.syncFriendLookupProfile());
    }
    _authSub = FirebaseService.authStateChanges.listen((u) {
      user.value = u;
      if (u != null) {
        Future<void>(() => FirebaseService.syncFriendLookupProfile());
      }
    });
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = '${info.version} (${info.buildNumber})';
    } catch (_) {
      appVersion.value = '—';
    }
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
        AppToast.showToast(
          'Google sign in cancelled'.tr,
          Icons.cancel_outlined,
          color: Colors.orange,
        );
      } else {
        AppToast.showToast(
          'Signed in successfully'.tr,
          Icons.check_circle_rounded,
          color: Colors.green,
        );
        final uid = result.user?.uid;
        if (uid != null) {
          SessionSyncService.instance.syncAfterLogin(uid).then((_) {
            _refreshDataControllers();
          });
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      // Push any in-session mutations before signing out so data is not lost.
      final uid = FirebaseService.currentUserId;
      if (uid != null) {
        await SessionSyncService.instance.flushCurrentSession(uid);
      }
      await FirebaseService.signOut();
      // Clear all local data so the next guest/account session starts fresh.
      SessionSyncService.instance.clearOnSignOut();
      await DbHelper.resetDatabase();
      AppCache.invalidateAll();
      AppGetStorage.clearUserData();
      _refreshDataControllers();
      AppToast.showToast(
        'Signed out successfully'.tr,
        Icons.logout_rounded,
        color: Colors.blueGrey,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh [LinkCollectionController], [CategoryController] and [FriendController] if they are
  /// registered. Called after login and logout.
  void _refreshDataControllers() {
    if (Get.isRegistered<LinkCollectionController>()) {
      Get.find<LinkCollectionController>().refreshData();
    }
    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().fetchCategories();
    }
    // Reload friends for the newly logged-in user. Skip when signing out
    // (currentUser is already null by this point).
    if (FirebaseService.currentUser != null && Get.isRegistered<FriendController>()) {
      Get.find<FriendController>().fetchFriends();
    }
  }

  // ── Support ────────────────────────────────────────────────────────────

  Future<void> sendFeedback() async {
    return Get.to(
      () => const FeedbackPage(),
      binding: FeedbackBinding(type: FeedbackType.feedback),
    );
  }

  Future<void> reportBug() async {
    return Get.to(
      () => const FeedbackPage(),
      binding: FeedbackBinding(type: FeedbackType.bugReport),
    );
  }

  Future<void> rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      AppToast.showToast(
        'Review request sent. Google Play may decide not to show the dialog every time.'.tr,
        Icons.info_outline_rounded,
        color: Colors.orange,
      );
    } else {
      await inAppReview.openStoreListing(appStoreId: 'com.phamtruong.keeplink');
      final uid = FirebaseService.currentUserId;
      AppGetStorage.setHasRatedApp(userId: uid);
    }
  }

  Future<void> showEditNameDialog() async {
    final saved = await Get.dialog<bool>(
      _EditNameDialog(initialName: user.value?.displayName ?? ''),
    );
    if (saved == true) {
      user.value = FirebaseService.currentUser;
      AppToast.showToast('Username updated successfully'.tr, Icons.edit_rounded);
    }
  }

  Future<void> copyPersonalFriendLink() async {
    final link = personalFriendLink;
    if (link == null) {
      AppToast.showToast('friend_sign_in_required'.tr, Icons.login_rounded, color: Colors.orange);
      return;
    }

    await Clipboard.setData(ClipboardData(text: link));
    AppToast.showToast('personal_link_copied'.tr, Icons.copy_rounded, color: Colors.green);
  }

  Future<void> savePersonalQrToDevice(Uint8List pngBytes) async {
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'keeplink_friend_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      final isSuccess = (result['isSuccess'] == true) || (result['filePath'] != null);
      if (isSuccess) {
        AppToast.showToast(
          'personal_qr_saved'.tr,
          Icons.download_done_rounded,
          color: Colors.green,
        );
        return;
      }
      AppToast.showToast(
        'personal_qr_save_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    } catch (_) {
      AppToast.showToast(
        'personal_qr_save_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    }
  }

  Future<void> sharePersonalQr(Uint8List pngBytes) async {
    final link = personalFriendLink;
    if (link == null) {
      AppToast.showToast('friend_sign_in_required'.tr, Icons.login_rounded, color: Colors.orange);
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/keep_link_friend_qr.png');
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles([XFile(file.path)], text: link, subject: 'Linkeep Friend QR');
    } catch (_) {
      AppToast.showToast(
        'personal_qr_share_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    }
  }

  Future<void> changeAvatar() async {
    if (user.value == null) {
      AppToast.showToast(
        'Please sign in to change avatar'.tr,
        Icons.login_rounded,
        color: Colors.orange,
      );
      return;
    }

    final uid = user.value!.uid;

    // Check daily limit before opening picker
    if (AppGetStorage.avatarChangesRemainingToday(uid) <= 0) {
      AppToast.showToast(
        'You can only change your avatar 2 times per day'.tr,
        Icons.block_rounded,
        color: Colors.red,
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    final pickedFile = File(picked.path);
    final pickedSize = await pickedFile.length();
    final lastFingerprint = AppGetStorage.getAvatarFingerprint(uid);

    if (lastFingerprint != null && lastFingerprint == pickedSize) {
      AppToast.showToast(
        'This is already your current avatar'.tr,
        Icons.image_rounded,
        color: Colors.orange,
      );
      return;
    }

    isUploadingAvatar.value = true;
    try {
      final url = await ImageKitService.uploadFile(
        file: pickedFile,
        folder: '/avatars/$uid',
        fileName: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (url == null) {
        AppToast.showToast(
          'Upload failed. Please try again.'.tr,
          Icons.error_outline_rounded,
          color: Colors.red,
        );
        return;
      }
      AppGetStorage.setAvatarFingerprint(uid, pickedSize);
      AppGetStorage.recordAvatarChange(uid);
      await FirebaseService.updatePhotoURL(url);
      user.value = FirebaseService.currentUser;
      AppToast.showToast(
        'Avatar updated successfully'.tr,
        Icons.check_circle_rounded,
        color: Colors.green,
      );
    } catch (e) {
      AppToast.showToast('Something went wrong'.tr, Icons.error_outline_rounded, color: Colors.red);
    } finally {
      isUploadingAvatar.value = false;
    }
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});
  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _nameController;
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    Utils.dimissKeyboard();
    final name = _nameController.text.trim();
    if (_loading) return;

    if (name.isEmpty) {
      setState(() => _errorText = 'Username must not be empty'.tr);
      return;
    }

    if (name.length < 3) {
      setState(() => _errorText = 'Username must be at least 3 characters'.tr);
      return;
    }

    if (name.length > 30) {
      setState(() => _errorText = 'Username must be at most 30 characters'.tr);
      return;
    }

    if (name == widget.initialName.trim()) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await FirebaseService.updateDisplayName(name);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: TextWidget(text: 'Edit Username'.tr, size: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(hintText: 'Enter your name'.tr, counterText: ''),
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextWidget(text: _errorText!, color: Colors.red, size: 12),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: TextWidget(text: 'Cancel'.tr),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextWidget(text: 'Save'.tr),
        ),
      ],
    );
  }
}
