// lib/services/storage_service.dart
//
// Handles uploading images to Firebase Storage.
// Used when users attach an image to a post.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ─── Pick Image (Camera or Gallery) ───────────────────────────────────────
  Future<XFile?> pickImage({
    required ImageSource source,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // ─── Pick Image from Gallery (legacy helper) ──────────────────────────────
  Future<XFile?> pickImageFromGallery() async {
    return pickImage(source: ImageSource.gallery);
  }

  // ─── Upload Profile Image ─────────────────────────────────────────────────
  /// Uploads user profile image to Firebase Storage and returns the download URL.
  /// Stores image at users/{userId}/profile.{extension}.
  Future<String?> uploadProfileImage({
    required String userId,
    required Uint8List imageBytes,
    String extension = 'jpg',
  }) async {
    try {
      final cleanExt = extension.toLowerCase().replaceAll('.', '');
      final mimeType = cleanExt == 'png'
          ? 'image/png'
          : cleanExt == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final ref = _storage.ref().child('users/$userId/profile.$cleanExt');

      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {'uploadedBy': userId},
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // ─── Delete Profile Image ─────────────────────────────────────────────────
  /// Deletes profile image from Firebase Storage if safe to do so.
  Future<void> deleteProfileImage({
    required String userId,
    String? photoUrl,
  }) async {
    // 1. Try deleting via download URL if it's a Firebase Storage URL
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        (photoUrl.contains('firebasestorage.googleapis.com') ||
            photoUrl.contains('firebasestorage.app'))) {
      try {
        final ref = _storage.refFromURL(photoUrl);
        await ref.delete();
        debugPrint('Deleted storage file via refFromURL: $photoUrl');
        return;
      } catch (e) {
        debugPrint('Could not delete storage file via URL: $e');
      }
    }

    // 2. Fallback: try deleting by standard path for this user
    for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
      try {
        final ref = _storage.ref().child('users/$userId/profile.$ext');
        await ref.delete();
        debugPrint('Deleted storage file via ref path: users/$userId/profile.$ext');
        break;
      } catch (e) {
        // File might not exist with this extension, ignore
      }
    }
  }

  // ─── Upload Post Image ────────────────────────────────────────────────────
  Future<String?> uploadPostImage(String postId, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('post_images/$postId.jpg');

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await ref.putFile(File(imageFile.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      return null;
    }
  }
}
