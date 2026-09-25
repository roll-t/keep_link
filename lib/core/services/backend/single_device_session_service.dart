import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/cache/sql_lite.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/services/backend/session_sync_service.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/page/link_collection_page.dart';

/// Enforces one active app session per Firebase user.
///
/// A successful interactive login replaces `users/{uid}/activeSession`.
/// Every signed-in installation watches that value and signs itself out when
/// another installation replaces it.
class SingleDeviceSessionService {
  SingleDeviceSessionService._();

  static final SingleDeviceSessionService instance =
      SingleDeviceSessionService._();

  static const Duration _requestTimeout = Duration(seconds: 8);

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _sessionSubscription;
  String? _watchedUserId;
  bool _initialized = false;
  bool _interactiveSignIn = false;
  bool _forcingSignOut = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final currentUser = FirebaseService.currentUser;
    if (currentUser != null) {
      await _validateRestoredSession(currentUser.uid);
    }

    FirebaseService.authStateChanges.listen((user) {
      if (_interactiveSignIn || _forcingSignOut) return;
      if (user == null) {
        unawaited(_stopWatching());
        return;
      }
      if (_watchedUserId == user.uid && _sessionSubscription != null) return;
      unawaited(_validateRestoredSession(user.uid));
    });
  }

  /// Signs in and atomically makes this installation the account's only
  /// active app session. A failure to register the session makes the whole
  /// sign-in fail, avoiding an unmonitored multi-device login.
  Future<UserCredential?> signInWithGoogle() async {
    _interactiveSignIn = true;
    await _stopWatching();
    try {
      final credential = await FirebaseService.signInWithGoogle();
      final user = credential?.user;
      if (user == null) return credential;

      await _claimNewSession(user.uid);
      return credential;
    } catch (_) {
      AppGetStorage.clearActiveSession();
      if (FirebaseService.currentUser != null) {
        try {
          await FirebaseService.signOut();
        } catch (error) {
          log('Rollback sign-in after session claim failure: $error');
        }
      }
      rethrow;
    } finally {
      _interactiveSignIn = false;
    }
  }

  /// Stops local monitoring before a user-requested sign-out. The remote
  /// marker intentionally remains: a concurrent newer login must not be
  /// deleted by an older device finishing sign-out slightly later.
  Future<void> signOutCurrentDevice() async {
    await _stopWatching();
    try {
      await FirebaseService.signOut();
    } finally {
      AppGetStorage.clearActiveSession();
    }
  }

  Future<void> _claimNewSession(String userId) async {
    final sessionId = _generateSessionId();
    final reference = _sessionReference(userId);

    await reference
        .set({'id': sessionId, 'signedInAt': ServerValue.timestamp})
        .timeout(_requestTimeout);

    AppGetStorage.saveActiveSession(userId: userId, sessionId: sessionId);
    _watchSession(userId, sessionId);
  }

  Future<void> _validateRestoredSession(String userId) async {
    if (_forcingSignOut || _interactiveSignIn) return;

    final localUserId = AppGetStorage.getActiveSessionUserId();
    final localSessionId = AppGetStorage.getActiveSessionId();
    final reference = _sessionReference(userId);

    try {
      final snapshot = await reference.get().timeout(_requestTimeout);
      final remoteSessionId = _readSessionId(snapshot.value);

      // Migration for accounts already signed in before this feature existed.
      // Only claim automatically when the server has no active session yet.
      if (remoteSessionId == null) {
        final migratedSessionId =
            localUserId == userId && localSessionId != null
            ? localSessionId
            : _generateSessionId();
        await reference
            .set({'id': migratedSessionId, 'signedInAt': ServerValue.timestamp})
            .timeout(_requestTimeout);
        AppGetStorage.saveActiveSession(
          userId: userId,
          sessionId: migratedSessionId,
        );
        _watchSession(userId, migratedSessionId);
        return;
      }

      if (localUserId != userId ||
          localSessionId == null ||
          remoteSessionId != localSessionId) {
        await _forceSignOut(userId);
        return;
      }

      _watchSession(userId, localSessionId);
    } on TimeoutException catch (error) {
      // Keep the restored Firebase session temporarily while offline. The
      // realtime listener will enforce the remote value after reconnection.
      log('Active session validation timed out: $error');
      if (localUserId == userId && localSessionId != null) {
        _watchSession(userId, localSessionId);
      }
    } catch (error) {
      log('Active session validation failed: $error');
      if (localUserId == userId && localSessionId != null) {
        _watchSession(userId, localSessionId);
      }
    }
  }

  void _watchSession(String userId, String localSessionId) {
    unawaited(_sessionSubscription?.cancel());
    _watchedUserId = userId;
    _sessionSubscription = _sessionReference(userId).onValue.listen(
      (event) {
        final remoteSessionId = _readSessionId(event.snapshot.value);
        if (remoteSessionId != localSessionId) {
          unawaited(_forceSignOut(userId));
        }
      },
      onError: (Object error) {
        log('Active session watcher error: $error');
      },
    );
  }

  Future<void> _forceSignOut(String userId) async {
    if (_forcingSignOut) return;
    if (FirebaseService.currentUserId != userId) return;
    _forcingSignOut = true;
    await _stopWatching();

    try {
      AppGetStorage.deactivateAccount(userId);
      SessionSyncService.instance.clearOnSignOut();

      try {
        await FirebaseService.signOut();
      } catch (error) {
        log('Forced Firebase sign-out failed: $error');
      }

      await DbHelper.resetDatabase();
      AppCache.invalidateAll();
      AppGetStorage.clearUserData(preserveSecurity: true);

      // During app bootstrap there is no navigator yet; Splash will naturally
      // open the guest state. At runtime rebuild the home route immediately.
      if (Get.key.currentContext != null) {
        Get.offAllNamed(LinkCollectionPage.routeName);
        Fluttertoast.showToast(
          msg: 'account_signed_in_on_another_device'.tr,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.danger,
          textColor: AppColors.white,
        );
      }
    } finally {
      _forcingSignOut = false;
    }
  }

  Future<void> _stopWatching() async {
    final subscription = _sessionSubscription;
    _sessionSubscription = null;
    _watchedUserId = null;
    await subscription?.cancel();
  }

  DatabaseReference _sessionReference(String userId) =>
      _database.ref('users/$userId/activeSession');

  static String? _readSessionId(Object? value) {
    if (value is! Map) return null;
    final id = value['id']?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  static String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
