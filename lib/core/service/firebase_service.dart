import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

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
}
