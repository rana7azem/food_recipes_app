import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  // Use lazy initialization to avoid "no instance" error
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Check if Firebase is initialized
  bool get isFirebaseInitialized => Firebase.apps.isNotEmpty;

  // Get current user
  User? get currentUser => isFirebaseInitialized ? _auth.currentUser : null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => 
      isFirebaseInitialized ? _auth.authStateChanges() : Stream.value(null);

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'fullName': fullName,
        'profilePictureUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    String? profilePictureUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
