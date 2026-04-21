import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const int _dailyFeedbackLimit = 1;
  static const int _dailyBugReportLimit = 3;

  // ────────────────────────────────────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────────────────────────────────────

  static Future<UserCredential?> signInWithGoogle() async {
    try {
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
    } on FirebaseAuthException catch (e) {
      log('Google sign in error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Google sign in error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      log('Sign out success');
    } catch (e) {
      log('Sign out error: $e');
    }
  }

  /// Update the display name of the currently signed-in user.
  static Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
      await _auth.currentUser?.reload();
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
      log('Photo URL updated: $photoUrl');
    } catch (e) {
      log('Update photo URL error: $e');
      rethrow;
    }
  }

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static String? get currentUserId => _auth.currentUser?.uid;

  // ────────────────────────────────────────────────────────────────────────
  // REALTIME DATABASE
  // ────────────────────────────────────────────────────────────────────────

  /// Fetch the entire user node (links + categories) — 1 GET request.
  /// Returns null if the node doesn't exist yet.
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _db.ref('users/$userId').get();
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
      await _db.ref('users/$userId').update(updates);
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
      final quotaSnapshot = await quotaRef.get();
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

      await _db.ref().update({
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
      });

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
}
