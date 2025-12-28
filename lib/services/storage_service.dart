import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

class StorageService {
  // Use lazy initialization to avoid "no instance" error
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Check if Firebase is initialized
  bool get _isFirebaseInitialized => Firebase.apps.isNotEmpty;

  // Upload profile picture
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$userId');
      final items = await ref.listAll();
      for (var item in items.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete profile picture: $e');
    }
  }
}
