import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/application/model/friend_request_model.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const int _dailyFeedbackLimit = 1;
  static const int _dailyBugReportLimit = 3;
  static const String _publicFriendProfilesPath = 'friendDirectory/profiles';
  static const String _friendRequestsKey = 'friendRequests';
  static const String _sentFriendRequestsKey = 'sentFriendRequests';
  static const String _friendsKey = 'friends';
  static const String _sharedWithKey = 'sharedWith';
  static const String _sharedCategoryAccessKey = 'sharedCategoryAccess';
  static const String _sharedLinksWithKey = 'sharedLinksWith';
  static const String _sharedLinkAccessKey = 'sharedLinkAccess';

  /// Hard cap for a single Realtime Database round-trip. Without this, a
  /// `.get()`/`.update()` call can hang indefinitely while offline — and
  /// several of these run on the app-startup path (see SessionSyncService),
  /// which would freeze the splash screen forever.
  static const Duration _requestTimeout = Duration(seconds: 8);

  // ────────────────────────────────────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────────────────────────────────────

  /// Returns the signed-in [UserCredential], or `null` if the user closed
  /// the account picker themselves (not an error). Any real failure (no
  /// network, bad config, etc.) is left to propagate so the caller can tell
  /// it apart from a plain cancel and show an accurate message — previously
  /// every failure was swallowed here and returned null exactly like a
  /// cancel, so a real error always surfaced to the user as "sign-in
  /// cancelled" with no way to know something actually went wrong.
  ///
  /// Does not sync the friend lookup profile itself — the caller
  /// (PersonalController) already reacts to `authStateChanges` and does
  /// that once; doing it here too would just be a second, redundant write.
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    log('Google sign in success: ${userCredential.user?.uid}');
    return userCredential;
  }

  static Future<void> signOut() async {
    // The Google-side sign-out is tolerated on failure (still counts as
    // "signed out" for our purposes) but Firebase Auth's own signOut() is
    // NOT — it used to be wrapped in the same try/catch, so a transient
    // Google Play Services hiccup on the first line would skip _auth.signOut()
    // entirely while the caller still believed sign-out succeeded and went on
    // to wipe all local data. That left the Firebase session still
    // authenticated server-side while the device had nothing left locally.
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      log('Google sign out error (continuing to sign out of Firebase): $e');
    }
    await _auth.signOut();
    log('Sign out success');
  }

  /// Update the display name of the currently signed-in user.
  static Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
      await _auth.currentUser?.reload();
      await syncFriendLookupProfile();
      log('Display name updated: $name');
    } catch (e) {
      log('Update display name error: $e');
      rethrow;
    }
  }

  /// Update the photo URL of the currently signed-in user.
  static Future<void> updatePhotoURL(String photoUrl) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
      await _auth.currentUser?.reload();
      await syncFriendLookupProfile();
      log('Photo URL updated: $photoUrl');
    } catch (e) {
      log('Update photo URL error: $e');
      rethrow;
    }
  }

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static String? get currentUserId => _auth.currentUser?.uid;

  static Future<Map<String, String?>?> findUserProfileByEmail(String rawEmail) async {
    final email = _normalizeEmail(rawEmail);
    if (email.isEmpty) return null;

    try {
      final lookupSnapshot = await _db
          .ref(_publicFriendProfilesPath)
          .orderByChild('email')
          .equalTo(email)
          .limitToFirst(1)
          .get()
          .timeout(_requestTimeout);
      if (!lookupSnapshot.exists || lookupSnapshot.value is! Map) return null;

      final matchedProfiles = Map<String, dynamic>.from(lookupSnapshot.value as Map);
      final entry = matchedProfiles.entries.firstWhere(
        (candidate) => candidate.value is Map,
        orElse: () => const MapEntry('', null),
      );
      final userId = entry.key.trim();
      if (userId.isEmpty || entry.value is! Map) return null;

      final profile = Map<String, dynamic>.from(entry.value as Map);
      final storedEmail = _pickString([profile['email']]) ?? email;
      final displayName = _pickString([
        profile['displayName'],
        profile['display_name'],
        profile['name'],
      ]);
      final photoUrl = _pickString([
        profile['photoUrl'],
        profile['photo_url'],
        profile['avatarUrl'],
      ]);

      return {
        'uid': userId,
        'displayName': displayName,
        'email': storedEmail,
        'photoUrl': photoUrl,
      };
    } catch (e) {
      log('Find user by email error: $e');
      return null;
    }
  }

  /// Keep a small public profile directory for friend discovery without reading
  /// the entire private users tree.
  static Future<void> syncFriendLookupProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final email = _normalizeEmail(user.email);
    if (email.isEmpty) return;

    final displayName = _pickString([user.displayName]) ?? email.split('@').first;
    final photoUrl = _pickString([user.photoURL]);

    try {
      await _db
          .ref()
          .update({
            '$_publicFriendProfilesPath/${user.uid}': {
              'email': email,
              'displayName': displayName,
              'photoUrl': photoUrl,
              'updatedAt': ServerValue.timestamp,
            },
          })
          .timeout(_requestTimeout);
      log('Friend lookup profile synced: ${user.uid}');
    } catch (e) {
      log('Sync friend lookup profile error: $e');
    }
  }

  static Future<void> sendFriendRequest({
    required String targetUserId,
    required String displayName,
    String? email,
    String? photoUrl,
    required String sourceLink,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to send a friend request.',
      );
    }
    if (targetUserId.isEmpty || targetUserId == currentUser.uid) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'invalid-argument',
        message: 'Invalid target user.',
      );
    }

    final now = DateTime.now().toIso8601String();
    final requesterDisplayName =
        _pickString([currentUser.displayName]) ??
        _normalizeEmail(currentUser.email).split('@').first;
    final requesterEmail = _normalizeEmail(currentUser.email);
    final requesterPhotoUrl = _pickString([currentUser.photoURL]);

    final incomingRequest = {
      'fromUserId': currentUser.uid,
      'displayName': requesterDisplayName,
      'email': requesterEmail,
      'photoUrl': requesterPhotoUrl,
      'sourceLink': sourceLink,
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    };

    final outgoingRequest = {
      'targetUserId': targetUserId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'sourceLink': sourceLink,
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    };

    try {
      await _db
          .ref('users/$targetUserId')
          .update({'$_friendRequestsKey/${currentUser.uid}': incomingRequest})
          .timeout(_requestTimeout);

      try {
        await _db
            .ref('users/${currentUser.uid}')
            .update({'$_sentFriendRequestsKey/$targetUserId': outgoingRequest})
            .timeout(_requestTimeout);
      } catch (e) {
        log('Send friend request mirror write warning: $e');
      }

      log('Friend request sent: ${currentUser.uid} -> $targetUserId');
    } catch (e) {
      log('Send friend request error: $e');
      rethrow;
    }
  }

  static Future<List<FriendRequestModel>> getIncomingFriendRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const <FriendRequestModel>[];

    try {
      final snapshot = await _db
          .ref('users/${currentUser.uid}/$_friendRequestsKey')
          .get()
          .timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value is! Map) return const <FriendRequestModel>[];

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => FriendRequestModel.fromJson(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .where((request) => request.status == 'pending')
          .toList()
        ..sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
    } catch (e) {
      log('Get incoming friend requests error: $e');
      return const <FriendRequestModel>[];
    }
  }

  static Stream<List<FriendRequestModel>> watchIncomingFriendRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.ref('users/$uid/$_friendRequestsKey').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) {
        return <FriendRequestModel>[];
      }
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      return raw.entries
          .where((e) => e.value is Map)
          .map((e) => FriendRequestModel.fromJson(e.key, Map<String, dynamic>.from(e.value as Map)))
          .where((r) => r.status == 'pending')
          .toList()
        ..sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
    });
  }

  static Future<List<String>> getOutgoingFriendRequestUserIds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const <String>[];

    try {
      final snapshot = await _db
          .ref('users/${currentUser.uid}/$_sentFriendRequestsKey')
          .get()
          .timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value is! Map) return const <String>[];

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.entries
          .where((entry) => entry.value is Map)
          .map((entry) => MapEntry(entry.key, Map<String, dynamic>.from(entry.value as Map)))
          .where((entry) => (entry.value['status'] ?? 'pending').toString() == 'pending')
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      log('Get outgoing friend requests error: $e');
      return const <String>[];
    }
  }

  static Future<List<FriendModel>> getRemoteFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const <FriendModel>[];

    try {
      final snapshot = await _db
          .ref('users/${currentUser.uid}/$_friendsKey')
          .get()
          .timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value is! Map) return const <FriendModel>[];

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.entries.where((entry) => entry.value is Map).map((entry) {
        final json = Map<String, dynamic>.from(entry.value as Map);
        json['id'] = entry.key;
        json['friend_user_id'] = json['friendUserId'] ?? entry.key;
        json['display_name'] = json['displayName'] ?? '';
        json['photo_url'] = json['photoUrl'];
        json['source_link'] = json['sourceLink'];
        json['created_at'] = json['createdAt'];
        json['updated_at'] = json['updatedAt'];
        return FriendModel.fromJson(json);
      }).toList()..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    } catch (e) {
      log('Get remote friends error: $e');
      return const <FriendModel>[];
    }
  }

  /// Stream theo dõi realtime node `users/$uid/friends`.
  /// Emit số lượng bạn bè mỗi khi có thay đổi — dùng để trigger sync cục bộ.
  static Stream<int> watchFriendsCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.ref('users/$uid/$_friendsKey').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) return 0;
      return (event.snapshot.value as Map).length;
    });
  }

  static Future<void> acceptFriendRequest(FriendRequestModel request) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to accept a friend request.',
      );
    }

    final now = DateTime.now().toIso8601String();
    final currentDisplayName =
        _pickString([currentUser.displayName]) ??
        _normalizeEmail(currentUser.email).split('@').first;
    final currentEmail = _normalizeEmail(currentUser.email);
    final currentPhotoUrl = _pickString([currentUser.photoURL]);

    final currentUserFriend = {
      'friendUserId': request.fromUserId,
      'displayName': request.displayName,
      'email': request.email,
      'photoUrl': request.photoUrl,
      'sourceLink': request.sourceLink,
      'createdAt': now,
      'updatedAt': now,
    };

    final requesterFriend = {
      'friendUserId': currentUser.uid,
      'displayName': currentDisplayName,
      'email': currentEmail,
      'photoUrl': currentPhotoUrl,
      'sourceLink': request.sourceLink,
      'createdAt': now,
      'updatedAt': now,
    };

    // Ghi vào node của NGƯỜI GỬI trước (rủi ro hơn — có thể bị permission-denied
    // do rules, hoặc mất mạng giữa chừng). Chỉ khi bước này chắc chắn thành công
    // mới xoá lời mời đang chờ ở node của mình. Nếu làm ngược lại (như code cũ),
    // lỡ bước ghi cho người gửi thất bại thì lời mời đã bị xoá khỏi node của
    // mình mất rồi — người gửi kẹt vĩnh viễn ở trạng thái "đã gửi" mà không ai
    // có thể bấm "Accept" lại được nữa vì request đã biến mất.
    try {
      await _db
          .ref('users/${request.fromUserId}')
          .update({
            '$_friendsKey/${currentUser.uid}': requesterFriend,
            '$_sentFriendRequestsKey/${currentUser.uid}': null,
          })
          .timeout(_requestTimeout);
    } catch (e) {
      log('Accept friend request error (requester side): $e');
      rethrow;
    }

    try {
      await _db
          .ref('users/${currentUser.uid}')
          .update({
            '$_friendsKey/${request.fromUserId}': currentUserFriend,
            '$_friendRequestsKey/${request.fromUserId}': null,
          })
          .timeout(_requestTimeout);
    } catch (e) {
      log('Accept friend request error (own side): $e');
      rethrow;
    }

    log('Friend request accepted: ${request.fromUserId} <-> ${currentUser.uid}');
  }

  static Future<void> declineFriendRequest(String fromUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to decline a friend request.',
      );
    }

    try {
      await _db
          .ref('users/${currentUser.uid}')
          .update({'$_friendRequestsKey/$fromUserId': null})
          .timeout(_requestTimeout);

      await _db
          .ref('users/$fromUserId')
          .update({'$_sentFriendRequestsKey/${currentUser.uid}': null})
          .timeout(_requestTimeout);

      log('Friend request declined: $fromUserId -> ${currentUser.uid}');
    } catch (e) {
      log('Decline friend request error: $e');
      rethrow;
    }
  }

  static Future<void> removeFriend(String friendUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to remove a friend.',
      );
    }

    // Bước 1: Dọn phía mình — luôn được phép vì ghi vào node của chính mình
    try {
      await _db
          .ref('users/${currentUser.uid}')
          .update({
            '$_friendsKey/$friendUserId': null,
            '$_sharedWithKey/$friendUserId': null,
            '$_sharedCategoryAccessKey/$friendUserId': null,
            '$_sharedLinksWithKey/$friendUserId': null,
            '$_sharedLinkAccessKey/$friendUserId': null,
          })
          .timeout(_requestTimeout);
    } catch (e) {
      log('Remove friend (own side) error: $e');
      rethrow;
    }

    // Bước 2: Dọn phía bạn — mỗi path riêng để lỗi permission không chặn cả lô.
    // Nếu Firebase rules không cho phép ghi node của người khác,
    // bỏ qua; bạn sẽ tự dọn khi friendsWatcher phát hiện bị xoá.
    try {
      await _db
          .ref('users/$friendUserId/$_friendsKey/${currentUser.uid}')
          .remove()
          .timeout(_requestTimeout);
    } catch (e) {
      log('Remove friend (friend side - friends) error: $e');
    }
    try {
      await _db
          .ref('users/$friendUserId/$_sharedWithKey/${currentUser.uid}')
          .remove()
          .timeout(_requestTimeout);
    } catch (e) {
      log('Remove friend (friend side - sharedWith) error: $e');
    }
    try {
      await _db
          .ref('users/$friendUserId/$_sharedCategoryAccessKey/${currentUser.uid}')
          .remove()
          .timeout(_requestTimeout);
    } catch (e) {
      log('Remove friend (friend side - sharedCategoryAccess) error: $e');
    }
    try {
      await _db
          .ref('users/$friendUserId/$_sharedLinksWithKey/${currentUser.uid}')
          .remove()
          .timeout(_requestTimeout);
    } catch (e) {
      log('Remove friend (friend side - sharedLinksWith) error: $e');
    }
    try {
      await _db
          .ref('users/$friendUserId/$_sharedLinkAccessKey/${currentUser.uid}')
          .remove()
          .timeout(_requestTimeout);
    } catch (e) {
      log('Remove friend (friend side - sharedLinkAccess) error: $e');
    }

    log('Friend removed: ${currentUser.uid} x $friendUserId');
  }

  // ────────────────────────────────────────────────────────────────────────
  // REALTIME DATABASE
  // ────────────────────────────────────────────────────────────────────────

  /// Fetch the entire user node (links + categories) — 1 GET request.
  /// Returns null if the node doesn't exist yet.
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _db.ref('users/$userId').get().timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value == null) return null;
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      log('Get user data error: $e');
      return null;
    }
  }

  /// Push all session mutations in a single multi-path update (1 request).
  /// Pass `null` as a value to delete that path.
  static Future<void> applyUserDelta(String userId, Map<String, dynamic> updates) async {
    if (updates.isEmpty) return;
    try {
      await _db.ref('users/$userId').update(updates).timeout(_requestTimeout);
      log('User delta applied: ${updates.length} paths');
    } catch (e) {
      log('Apply user delta error: $e');
      rethrow;
    }
  }

  /// Submit a feedback or bug report.
  /// [type] should be 'feedback' or 'bug_report'.
  ///
  /// Write directly to a user-scoped path to match restricted rules and
  /// avoid noisy permission-denied logs from an initial global write attempt.
  static Future<void> submitFeedback({required String type, required String message}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to submit feedback.',
      );
    }

    final now = DateTime.now();
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final quotaRef = _db.ref('users/$uid/feedbackQuota/$dayKey');

    try {
      final quotaSnapshot = await quotaRef.get().timeout(_requestTimeout);
      final quotaData = quotaSnapshot.exists && quotaSnapshot.value is Map
          ? Map<String, dynamic>.from(quotaSnapshot.value as Map)
          : <String, dynamic>{};

      final feedbackCount = (quotaData['feedback'] as num?)?.toInt() ?? 0;
      final bugReportCount = (quotaData['bug_report'] as num?)?.toInt() ?? 0;

      if (type == 'feedback' && feedbackCount >= _dailyFeedbackLimit) {
        throw FirebaseException(
          plugin: 'firebase_database',
          code: 'quota-exceeded',
          message: 'Daily feedback limit reached.',
        );
      }

      if (type == 'bug_report' && bugReportCount >= _dailyBugReportLimit) {
        throw FirebaseException(
          plugin: 'firebase_database',
          code: 'quota-exceeded',
          message: 'Daily bug report limit reached.',
        );
      }

      final feedbackRef = _db.ref('users/$uid/feedback').push();
      final nextFeedbackCount = type == 'feedback' ? feedbackCount + 1 : feedbackCount;
      final nextBugReportCount = type == 'bug_report' ? bugReportCount + 1 : bugReportCount;

      await _db
          .ref()
          .update({
            'users/$uid/feedback/${feedbackRef.key}': {
              'type': type,
              'message': message,
              'email': _auth.currentUser?.email ?? '',
              'dayKey': dayKey,
              'timestamp': ServerValue.timestamp,
            },
            'users/$uid/feedbackQuota/$dayKey/feedback': nextFeedbackCount,
            'users/$uid/feedbackQuota/$dayKey/bug_report': nextBugReportCount,
            'users/$uid/feedbackQuota/$dayKey/updatedAt': ServerValue.timestamp,
          })
          .timeout(_requestTimeout);

      log(
        'Feedback submitted: users/$uid/feedback ($type) - '
        'quota today feedback=$nextFeedbackCount, bug_report=$nextBugReportCount',
      );
    } on FirebaseException {
      rethrow;
    } catch (e) {
      log('Submit feedback error: $e');
      rethrow;
    }
  }

  static String? _pickString(List<dynamic> values) {
    for (final value in values) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }
    return null;
  }

  static String _normalizeEmail(String? value) => value?.trim().toLowerCase() ?? '';

  // ────────────────────────────────────────────────────────────────────────
  // CATEGORY SHARING
  // ────────────────────────────────────────────────────────────────────────

  /// Share [categoryId] with [friendUid].
  /// Writes to two paths atomically (per-user updates to avoid root write):
  ///   users/$ownerUid/sharedWith/$friendUid/$categoryId: true
  ///   users/$friendUid/sharedCategoryAccess/$ownerUid/$categoryId: true
  static Future<void> shareCategory({required String friendUid, required String categoryId}) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to share a category.',
      );
    }

    try {
      await _db
          .ref('users/${owner.uid}/$_sharedWithKey/$friendUid')
          .update({categoryId: true})
          .timeout(_requestTimeout);
      try {
        await _db
            .ref('users/$friendUid/$_sharedCategoryAccessKey/${owner.uid}')
            .update({categoryId: ServerValue.timestamp})
            .timeout(_requestTimeout);
      } catch (e) {
        // Same rollback as shareLink(): don't leave the owner's own node
        // claiming a share that the friend never actually received.
        await _db
            .ref('users/${owner.uid}/$_sharedWithKey/$friendUid/$categoryId')
            .remove()
            .timeout(_requestTimeout)
            .catchError((_) {});
        rethrow;
      }
      log('Category shared: ${owner.uid} -> $friendUid (cat: $categoryId)');
    } catch (e) {
      log('Share category error: $e');
      rethrow;
    }
  }

  /// Revoke sharing of [categoryId] with [friendUid].
  static Future<void> unshareCategory({
    required String friendUid,
    required String categoryId,
  }) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to unshare a category.',
      );
    }

    try {
      await _db
          .ref('users/${owner.uid}/$_sharedWithKey/$friendUid/$categoryId')
          .remove()
          .timeout(_requestTimeout);
      await _db
          .ref('users/$friendUid/$_sharedCategoryAccessKey/${owner.uid}/$categoryId')
          .remove()
          .timeout(_requestTimeout);
      log('Category unshared: ${owner.uid} -> $friendUid (cat: $categoryId)');
    } catch (e) {
      log('Unshare category error: $e');
      rethrow;
    }
  }

  /// Returns list of friend UIDs that [categoryId] is currently shared with.
  /// Returns all sharing entries for the current user in one read.
  /// Result: { friendUid: [catId1, catId2, ...], ... }
  static Future<Map<String, List<String>>> getAllSharedWith() async {
    final owner = _auth.currentUser;
    if (owner == null) return {};

    try {
      final snapshot = await _db
          .ref('users/${owner.uid}/$_sharedWithKey')
          .get()
          .timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value is! Map) return {};

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      final result = <String, List<String>>{};
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        final catMap = Map<String, dynamic>.from(entry.value as Map);
        result[entry.key] = catMap.keys.toList();
      }
      return result;
    } catch (e) {
      log('Get all sharedWith error: $e');
      return {};
    }
  }

  static Future<List<String>> getCategorySharedFriendUids(String categoryId) async {
    final owner = _auth.currentUser;
    if (owner == null) return const [];

    try {
      final snapshot = await _db
          .ref('users/${owner.uid}/$_sharedWithKey')
          .get()
          .timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value is! Map) return const [];

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.entries
          .where(
            (entry) =>
                entry.value is Map &&
                (Map<String, dynamic>.from(entry.value as Map)[categoryId]) == true,
          )
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      log('Get category shared friend uids error: $e');
      return const [];
    }
  }

  /// Remove all sharing records for [categoryId] when the category is deleted.
  static Future<void> revokeAllCategoryShares(String categoryId) async {
    final owner = _auth.currentUser;
    if (owner == null) return;

    try {
      final sharedFriendUids = await getCategorySharedFriendUids(categoryId);
      for (final friendUid in sharedFriendUids) {
        await unshareCategory(friendUid: friendUid, categoryId: categoryId);
      }
      log('All shares revoked for category: $categoryId');
    } catch (e) {
      log('Revoke all category shares error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // INDIVIDUAL LINK SHARING
  // ────────────────────────────────────────────────────────────────────────

  /// Share [linkId] with [friendUid].
  static Future<void> shareLink({required String friendUid, required String linkId}) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to share a link.',
      );
    }

    try {
      await _db
          .ref('users/${owner.uid}/$_sharedLinksWithKey/$friendUid')
          .update({linkId: true})
          .timeout(_requestTimeout);
      try {
        await _db
            .ref('users/$friendUid/$_sharedLinkAccessKey/${owner.uid}')
            .update({linkId: ServerValue.timestamp})
            .timeout(_requestTimeout);
      } catch (e) {
        // Own-side write above already succeeded — without this rollback the
        // owner's sharedLinksWith node would keep saying "shared" for a
        // friend who never actually got access (e.g. RTDB rules rejecting
        // the cross-user write), which desyncs the share sheet's UI from
        // reality until the link is deleted.
        await _db
            .ref('users/${owner.uid}/$_sharedLinksWithKey/$friendUid/$linkId')
            .remove()
            .timeout(_requestTimeout)
            .catchError((_) {});
        rethrow;
      }
      log('Link shared: ${owner.uid} -> $friendUid (link: $linkId)');
    } catch (e) {
      log('Share link error: $e');
      rethrow;
    }
  }

  /// Revoke sharing of [linkId] with [friendUid].
  static Future<void> unshareLink({required String friendUid, required String linkId}) async {
    final owner = _auth.currentUser;
    if (owner == null) {
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'unauthenticated',
        message: 'Sign in is required to unshare a link.',
      );
    }

    try {
      await _db
          .ref('users/${owner.uid}/$_sharedLinksWithKey/$friendUid/$linkId')
          .remove()
          .timeout(_requestTimeout);
      await _db
          .ref('users/$friendUid/$_sharedLinkAccessKey/${owner.uid}/$linkId')
          .remove()
          .timeout(_requestTimeout);
      log('Link unshared: ${owner.uid} -> $friendUid (link: $linkId)');
    } catch (e) {
      log('Unshare link error: $e');
      rethrow;
    }
  }

  /// Returns list of friend UIDs that [linkId] is currently shared with.
  static Future<List<String>> getLinkSharedFriendUids(String linkId) async {
    final owner = _auth.currentUser;
    if (owner == null) return const [];

    try {
      final snapshot = await _db
          .ref('users/${owner.uid}/$_sharedLinksWithKey')
          .get()
          .timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value is! Map) return const [];

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.entries
          .where(
            (entry) =>
                entry.value is Map &&
                (Map<String, dynamic>.from(entry.value as Map)[linkId]) == true,
          )
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      log('Get link shared friend uids error: $e');
      return const [];
    }
  }

  /// Remove all sharing records for [linkId] when the link is deleted.
  static Future<void> revokeAllLinkShares(String linkId) async {
    final owner = _auth.currentUser;
    if (owner == null) return;

    try {
      final sharedFriendUids = await getLinkSharedFriendUids(linkId);
      for (final friendUid in sharedFriendUids) {
        await unshareLink(friendUid: friendUid, linkId: linkId);
      }
      log('All shares revoked for link: $linkId');
    } catch (e) {
      log('Revoke all link shares error: $e');
    }
  }

  /// Fetch all individual links that friends have shared with the current user.
  static Future<List<SharedIndividualLinkModel>> getSharedIndividualLinksFromFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const [];

    try {
      final accessSnapshot = await _db
          .ref('users/${currentUser.uid}/$_sharedLinkAccessKey')
          .get()
          .timeout(_requestTimeout);
      if (!accessSnapshot.exists || accessSnapshot.value is! Map) return const [];

      final accessMap = Map<String, dynamic>.from(accessSnapshot.value as Map);

      final perOwnerResults = await Future.wait(
        accessMap.entries
            .where((entry) => entry.value is Map)
            .map(
              (entry) => _fetchSharedLinksForOwner(
                entry.key,
                Map<String, dynamic>.from(entry.value as Map),
              ),
            ),
      );

      return perOwnerResults.expand((list) => list).toList();
    } catch (e) {
      log('Get shared individual links error: $e');
      return const [];
    }
  }

  static Future<List<SharedIndividualLinkModel>> _fetchSharedLinksForOwner(
    String ownerUid,
    Map<String, dynamic> linkMap,
  ) async {
    if (linkMap.isEmpty) return const [];

    final results = await Future.wait<dynamic>([
      _fetchOwnerProfile(ownerUid),
      Future.wait(
        linkMap.entries.map((entry) => _fetchSharedLink(ownerUid, entry.key, entry.value)),
      ),
    ]);

    final profile = results[0] as ({String? displayName, String? photoUrl})?;
    final ownerDisplayName = profile?.displayName ?? ownerUid;
    final ownerPhotoUrl = profile?.photoUrl;

    final rawLinks =
        (results[1] as List<({String linkId, Map<String, dynamic> linkJson, DateTime? sharedAt})?>)
            .whereType<({String linkId, Map<String, dynamic> linkJson, DateTime? sharedAt})>();

    return rawLinks
        .map(
          (raw) => SharedIndividualLinkModel.fromJson(
            ownerUid: ownerUid,
            ownerDisplayName: ownerDisplayName,
            ownerPhotoUrl: ownerPhotoUrl,
            linkId: raw.linkId,
            linkJson: raw.linkJson,
            sharedAt: raw.sharedAt,
          ),
        )
        .toList();
  }

  static Future<({String linkId, Map<String, dynamic> linkJson, DateTime? sharedAt})?>
  _fetchSharedLink(String ownerUid, String linkId, dynamic rawSharedAt) async {
    try {
      final sharedAt = rawSharedAt is int ? DateTime.fromMillisecondsSinceEpoch(rawSharedAt) : null;

      final linkSnap = await _db
          .ref('users/$ownerUid/links/$linkId')
          .get()
          .timeout(_requestTimeout);
      if (!linkSnap.exists || linkSnap.value is! Map) return null;

      return (
        linkId: linkId,
        linkJson: Map<String, dynamic>.from(linkSnap.value as Map),
        sharedAt: sharedAt,
      );
    } catch (e) {
      log('Fetch shared link error for link $linkId: $e');
      return null;
    }
  }

  /// Fetch all categories that friends have shared with the current user.
  /// Returns a list of [SharedCategoryModel].
  ///
  /// Every owner is resolved concurrently, and within each owner the profile
  /// lookup, every shared category, and every category's link count are also
  /// fetched concurrently. This is the same set of reads as a naive
  /// sequential N+1 loop (RTDB security rules only allow reading one
  /// category/link-count at a time, so the read paths can't be batched) —
  /// but fanned out over the single already-open RTDB connection instead of
  /// awaited one by one, so wall-clock time is bounded by the slowest single
  /// request instead of the sum of all of them.
  static Future<List<SharedCategoryModel>> getSharedCategoriesFromFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const [];

    try {
      // Step 1: Get the access index  users/$me/sharedCategoryAccess/$ownerUid/$catId
      final accessSnapshot = await _db
          .ref('users/${currentUser.uid}/$_sharedCategoryAccessKey')
          .get()
          .timeout(_requestTimeout);
      if (!accessSnapshot.exists || accessSnapshot.value is! Map) return const [];

      final accessMap = Map<String, dynamic>.from(accessSnapshot.value as Map);

      final perOwnerResults = await Future.wait(
        accessMap.entries
            .where((entry) => entry.value is Map)
            .map(
              (entry) => _fetchSharedCategoriesForOwner(
                entry.key,
                Map<String, dynamic>.from(entry.value as Map),
              ),
            ),
      );

      return perOwnerResults.expand((list) => list).toList();
    } catch (e) {
      log('Get shared categories error: $e');
      return const [];
    }
  }

  /// Resolves every category [ownerUid] shared with the current user
  /// (`catMap`: catId -> raw sharedAt). Owner profile lookup and every
  /// category fetch run concurrently.
  static Future<List<SharedCategoryModel>> _fetchSharedCategoriesForOwner(
    String ownerUid,
    Map<String, dynamic> catMap,
  ) async {
    if (catMap.isEmpty) return const [];

    final results = await Future.wait<dynamic>([
      _fetchOwnerProfile(ownerUid),
      Future.wait(
        catMap.entries.map(
          (catEntry) => _fetchSharedCategory(ownerUid, catEntry.key, catEntry.value),
        ),
      ),
    ]);

    final profile = results[0] as ({String? displayName, String? photoUrl})?;
    final ownerDisplayName = profile?.displayName ?? ownerUid;
    final ownerPhotoUrl = profile?.photoUrl;

    final rawCategories =
        (results[1]
                as List<
                  ({
                    String categoryId,
                    Map<String, dynamic> categoryJson,
                    int linkCount,
                    DateTime? sharedAt,
                  })?
                >)
            .whereType<
              ({
                String categoryId,
                Map<String, dynamic> categoryJson,
                int linkCount,
                DateTime? sharedAt,
              })
            >();

    return rawCategories
        .map(
          (raw) => SharedCategoryModel.fromJson(
            ownerUid: ownerUid,
            ownerDisplayName: ownerDisplayName,
            ownerPhotoUrl: ownerPhotoUrl,
            categoryId: raw.categoryId,
            categoryJson: raw.categoryJson,
            linkCount: raw.linkCount,
            sharedAt: raw.sharedAt,
          ),
        )
        .toList();
  }

  /// Resolve a friend's public display name/photo from `friendDirectory`.
  static Future<({String? displayName, String? photoUrl})?> _fetchOwnerProfile(
    String ownerUid,
  ) async {
    try {
      final profileSnap = await _db
          .ref('$_publicFriendProfilesPath/$ownerUid')
          .get()
          .timeout(_requestTimeout);
      if (!profileSnap.exists || profileSnap.value is! Map) return null;
      final profile = Map<String, dynamic>.from(profileSnap.value as Map);
      return (
        displayName: _pickString([profile['displayName'], profile['display_name']]),
        photoUrl: _pickString([profile['photoUrl'], profile['photo_url']]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch one shared category node plus its live link count.
  /// Returns null if the category no longer exists or the fetch fails —
  /// callers should skip null entries rather than fail the whole batch.
  static Future<
    ({String categoryId, Map<String, dynamic> categoryJson, int linkCount, DateTime? sharedAt})?
  >
  _fetchSharedCategory(String ownerUid, String catId, dynamic rawSharedAt) async {
    try {
      // Parse sharedAt timestamp (new data = int ms, old data = bool true)
      final sharedAt = rawSharedAt is int ? DateTime.fromMillisecondsSinceEpoch(rawSharedAt) : null;

      final catSnap = await _db
          .ref('users/$ownerUid/categories/$catId')
          .get()
          .timeout(_requestTimeout);
      if (!catSnap.exists || catSnap.value is! Map) return null;

      int linkCount = 0;
      try {
        final linksSnap = await _db
            .ref('users/$ownerUid/links')
            .orderByChild('categoryId')
            .equalTo(catId)
            .get()
            .timeout(_requestTimeout);
        if (linksSnap.exists && linksSnap.value is Map) {
          linkCount = (linksSnap.value as Map).length;
        }
      } catch (e) {
        log('Fetch link count error for cat $catId: $e');
      }

      return (
        categoryId: catId,
        categoryJson: Map<String, dynamic>.from(catSnap.value as Map),
        linkCount: linkCount,
        sharedAt: sharedAt,
      );
    } catch (e) {
      log('Fetch shared category error ($catId): $e');
      return null;
    }
  }

  /// Watch `users/$uid/sharedCategoryAccess` for real-time changes.
  /// Emits a flat Set of "${ownerUid}/${categoryId}" strings every time
  /// the node changes — callers can diff to detect new shares.
  static Stream<Set<String>> watchSharedCategoryAccess() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.ref('users/$uid/$_sharedCategoryAccessKey').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) return <String>{};
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      final keys = <String>{};
      for (final ownerEntry in raw.entries) {
        if (ownerEntry.value is! Map) continue;
        final catMap = Map<String, dynamic>.from(ownerEntry.value as Map);
        for (final catId in catMap.keys) {
          keys.add('${ownerEntry.key}/$catId');
        }
      }
      return keys;
    });
  }

  /// Watch all links belonging to [ownerUid] and count per [sharedCatIds].
  /// Emits a map of catId → link count whenever any link changes for that owner.
  static Stream<Map<String, int>> watchOwnerLinksCount({
    required String ownerUid,
    required Set<String> sharedCatIds,
  }) {
    if (sharedCatIds.isEmpty) return const Stream.empty();
    return _db.ref('users/$ownerUid/links').onValue.map((event) {
      final counts = <String, int>{for (final id in sharedCatIds) id: 0};
      if (!event.snapshot.exists || event.snapshot.value is! Map) return counts;
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        final link = Map<String, dynamic>.from(entry.value as Map);
        final catId = link['categoryId'] as String?;
        if (catId != null && counts.containsKey(catId)) {
          counts[catId] = (counts[catId] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  /// Fetch the links belonging to [categoryId] from [ownerUid]'s account.
  /// Returns raw JSON maps suitable for constructing [LinkModel].
  static Future<List<Map<String, dynamic>>> fetchSharedCategoryLinks({
    required String ownerUid,
    required String categoryId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const [];

    try {
      final snapshot = await _db
          .ref('users/$ownerUid/links')
          .orderByChild('categoryId')
          .equalTo(categoryId)
          .get()
          .timeout(_requestTimeout);
      if (!snapshot.exists || snapshot.value is! Map) return const [];

      final raw = Map<String, dynamic>.from(snapshot.value as Map);
      return raw.entries.where((entry) => entry.value is Map).map((entry) {
        final map = Map<String, dynamic>.from(entry.value as Map);
        map['id'] = entry.key;
        return map;
      }).toList()..sort((a, b) {
        final aTime = a['createdAt'] as String? ?? '';
        final bTime = b['createdAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });
    } catch (e) {
      log('Fetch shared category links error: $e');
      return const [];
    }
  }

  /// Watch links of [ownerUid] filtered by [categoryId] in real-time.
  static Stream<List<Map<String, dynamic>>> watchSharedCategoryLinks({
    required String ownerUid,
    required String categoryId,
  }) {
    if (_auth.currentUser == null) return const Stream.empty();

    return _db
        .ref('users/$ownerUid/links')
        .orderByChild('categoryId')
        .equalTo(categoryId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists || event.snapshot.value is! Map) {
            return <Map<String, dynamic>>[];
          }
          final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
          return (raw.entries.where((e) => e.value is Map).map((e) {
            final map = Map<String, dynamic>.from(e.value as Map);
            map['id'] = e.key;
            return map;
          }).toList()..sort((a, b) {
            final aTime = a['createdAt'] as String? ?? '';
            final bTime = b['createdAt'] as String? ?? '';
            return bTime.compareTo(aTime);
          }));
        });
  }
}
