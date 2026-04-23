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
import 'package:keep_link/features/friend/application/model/friend_request_model.dart';

class FriendController extends GetxController {
  static const int maxFriends = 10;

  final searchController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool favoritesOnly = false.obs;
  final RxList<FriendModel> visibleFriends = <FriendModel>[].obs;
  final RxList<FriendRequestModel> incomingRequests = <FriendRequestModel>[].obs;
  final RxList<String> pendingRequestUserIds = <String>[].obs;

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
      await _syncRemoteFriendState();
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

    return _sendFriendRequest(
      userId: payload.userId,
      displayName: payload.displayName,
      email: payload.email,
      photoUrl: payload.photoUrl,
      sourceLink: payload.rawLink,
    );
  }

  Future<bool> addFriendFromEmail(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || !GetUtils.isEmail(email) || !email.endsWith('@gmail.com')) {
      Fluttertoast.showToast(msg: 'friend_invalid_email'.tr);
      return false;
    }

    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      Fluttertoast.showToast(msg: 'friend_sign_in_required'.tr);
      return false;
    }
    if (hasReachedLimit) {
      Fluttertoast.showToast(msg: 'friend_limit_reached'.trParams({'0': '$maxFriends'}));
      return false;
    }
    if ((currentUser.email ?? '').trim().toLowerCase() == email) {
      Fluttertoast.showToast(msg: 'friend_cannot_add_self'.tr);
      return false;
    }

    final existingByEmail = AppCache.friends.firstWhereOrNull(
      (friend) => (friend.email ?? '').trim().toLowerCase() == email,
    );
    if (existingByEmail != null) {
      Fluttertoast.showToast(msg: 'friend_already_exists'.tr);
      return false;
    }

    final profile = await FirebaseService.findUserProfileByEmail(email);
    if (profile == null) {
      Fluttertoast.showToast(msg: 'friend_email_not_found'.tr);
      return false;
    }

    final userId = profile['uid'] ?? '';
    final profileDisplayName = profile['displayName'] ?? '';
    final profileEmail = profile['email'];
    final profilePhoto = profile['photoUrl'];

    if (userId.isEmpty) {
      Fluttertoast.showToast(msg: 'friend_email_not_found'.tr);
      return false;
    }
    if (userId == currentUser.uid) {
      Fluttertoast.showToast(msg: 'friend_cannot_add_self'.tr);
      return false;
    }

    final fallbackName = (profileEmail ?? email).split('@').first;
    final safeDisplayName = profileDisplayName.trim().isEmpty ? fallbackName : profileDisplayName;

    return _sendFriendRequest(
      userId: userId,
      displayName: safeDisplayName,
      email: profileEmail,
      photoUrl: profilePhoto,
      sourceLink: 'email:$email',
    );
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

  Future<void> acceptFriendRequest(FriendRequestModel request) async {
    if (hasReachedLimit) {
      Fluttertoast.showToast(msg: 'friend_limit_reached'.trParams({'0': '$maxFriends'}));
      return;
    }

    try {
      await FirebaseService.acceptFriendRequest(request);
      await _syncRemoteFriendState();
      Fluttertoast.showToast(msg: 'friend_request_accepted'.tr);
    } catch (_) {
      Fluttertoast.showToast(msg: 'friend_request_action_failed'.tr);
    }
  }

  Future<void> declineFriendRequest(FriendRequestModel request) async {
    try {
      await FirebaseService.declineFriendRequest(request.fromUserId);
      incomingRequests.removeWhere((item) => item.fromUserId == request.fromUserId);
      Fluttertoast.showToast(msg: 'friend_request_declined'.tr);
    } catch (_) {
      Fluttertoast.showToast(msg: 'friend_request_action_failed'.tr);
    }
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
        await FirebaseService.removeFriend(friend.friendUserId);
        await _syncRemoteFriendState();
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

  Future<bool> _sendFriendRequest({
    required String userId,
    required String displayName,
    String? email,
    String? photoUrl,
    required String sourceLink,
  }) async {
    final existing = AppCache.friends.firstWhereOrNull((friend) => friend.friendUserId == userId);
    if (existing != null) {
      Fluttertoast.showToast(msg: 'friend_already_exists'.tr);
      return false;
    }

    final incoming = incomingRequests.firstWhereOrNull((request) => request.fromUserId == userId);
    if (incoming != null) {
      await acceptFriendRequest(incoming);
      return true;
    }

    if (pendingRequestUserIds.contains(userId)) {
      Fluttertoast.showToast(msg: 'friend_request_already_sent'.tr);
      return false;
    }

    try {
      await FirebaseService.sendFriendRequest(
        targetUserId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        sourceLink: sourceLink,
      );
      pendingRequestUserIds.add(userId);
      Fluttertoast.showToast(msg: 'friend_request_sent'.tr);
      return true;
    } catch (_) {
      Fluttertoast.showToast(msg: 'friend_request_action_failed'.tr);
      return false;
    }
  }

  Future<void> _syncRemoteFriendState() async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      incomingRequests.clear();
      pendingRequestUserIds.clear();
      return;
    }

    final results = await Future.wait<dynamic>([
      FirebaseService.getRemoteFriends(),
      FirebaseService.getIncomingFriendRequests(),
      FirebaseService.getOutgoingFriendRequestUserIds(),
    ]);

    final remoteFriends = results[0] as List<FriendModel>;
    final requests = results[1] as List<FriendRequestModel>;
    final outgoingIds = results[2] as List<String>;

    await FriendRepository.replaceAll(remoteFriends);
    incomingRequests.assignAll(requests);
    pendingRequestUserIds.assignAll(outgoingIds);
  }
}
