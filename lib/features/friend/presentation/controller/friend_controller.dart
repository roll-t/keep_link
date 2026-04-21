import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/repository/friend_repository.dart';
import 'package:keep_link/core/service/firebase_service.dart';
import 'package:keep_link/core/service/friend_connection_service.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';

class FriendController extends GetxController {
  static const int maxFriends = 10;

  final searchController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool favoritesOnly = false.obs;
  final RxList<FriendModel> visibleFriends = <FriendModel>[].obs;

  int get totalFriends => AppCache.friends.length;
  int get favoriteFriends => AppCache.friends.where((friend) => friend.isFavorite).length;
  int get remainingSlots => maxFriends - totalFriends;
  bool get hasReachedLimit => totalFriends >= maxFriends;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applyFilters);
    ever(AppCache.friends, (_) => _applyFilters());
    fetchFriends();
  }

  @override
  void onClose() {
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchFriends() async {
    try {
      isLoading.value = true;
      await FriendRepository.ensureLoaded();
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFavoritesOnly() {
    favoritesOnly.value = !favoritesOnly.value;
    _applyFilters();
  }

  Future<bool> addFriendFromLink(String rawInput) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      Fluttertoast.showToast(msg: 'friend_sign_in_required'.tr);
      return false;
    }
    if (hasReachedLimit) {
      Fluttertoast.showToast(msg: 'friend_limit_reached'.trParams({'0': '$maxFriends'}));
      return false;
    }

    final payload = FriendConnectionService.parseLink(rawInput);
    if (payload == null) {
      Fluttertoast.showToast(msg: 'friend_invalid_link'.tr);
      return false;
    }
    if (payload.userId == currentUser.uid) {
      Fluttertoast.showToast(msg: 'friend_cannot_add_self'.tr);
      return false;
    }

    final existing = AppCache.friends.firstWhereOrNull(
      (friend) => friend.friendUserId == payload.userId,
    );
    if (existing != null) {
      Fluttertoast.showToast(msg: 'friend_already_exists'.tr);
      return false;
    }

    final now = DateTime.now();
    final friend = FriendModel(
      id: payload.userId,
      friendUserId: payload.userId,
      displayName: payload.displayName,
      email: payload.email,
      photoUrl: payload.photoUrl,
      sourceLink: payload.rawLink,
      createdAt: now,
      updatedAt: now,
    );

    await FriendRepository.insert(friend);
    Fluttertoast.showToast(msg: 'friend_added_success'.tr);
    _applyFilters();
    return true;
  }

  Future<String?> readClipboardLink() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<bool> addFriendFromClipboard() async {
    final text = await readClipboardLink();
    if (text == null) {
      Fluttertoast.showToast(msg: 'friend_clipboard_empty'.tr);
      return false;
    }
    return addFriendFromLink(text);
  }

  Future<void> toggleFavorite(FriendModel friend) async {
    final updated = friend.copyWith(isFavorite: !friend.isFavorite, updatedAt: DateTime.now());
    await FriendRepository.update(updated);
  }

  void confirmDeleteFriend(FriendModel friend) {
    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: 'Delete Friend'.tr,
      content: 'delete_friend_confirm'.trParams({'0': friend.displayName}),
      confirmText: 'Delete'.tr,
      cancelText: 'Cancel'.tr,
      onConfirm: () async {
        await FriendRepository.delete(friend.id ?? '');
        Get.back();
        Fluttertoast.showToast(msg: 'friend_deleted_success'.tr);
      },
      onCancel: Get.back,
    );
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    final filtered = AppCache.friends.where((friend) {
      if (favoritesOnly.value && !friend.isFavorite) {
        return false;
      }
      if (query.isEmpty) return true;

      return friend.displayName.toLowerCase().contains(query) ||
          (friend.email?.toLowerCase().contains(query) ?? false) ||
          friend.friendUserId.toLowerCase().contains(query);
    }).toList();

    visibleFriends.assignAll(filtered);
  }
}
