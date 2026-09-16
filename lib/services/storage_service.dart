// lib/services/storage_service.dart
//
// Handles uploading images to Firebase Storage.
// Used when users add a profile photo or attach an image to a post.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ─── Pick Image ───────────────────────────────────────────────────────────
  // Opens the gallery to let the user pick a photo
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,       // Resize to max 800px wide to save storage
        maxHeight: 800,
        imageQuality: 85,    // Compress slightly to reduce file size
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // ─── Upload Profile Photo ─────────────────────────────────────────────────
  // Uploads the photo and returns the download URL
  Future<String?> uploadProfilePhoto(String userId, XFile imageFile) async {
    try {
      // The path in Firebase Storage: profile_photos/user_001.jpg
      final ref = _storage.ref().child('profile_photos/$userId.jpg');

      // Upload the file (web uses bytes, mobile uses file path)
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await ref.putFile(File(imageFile.path));
      }

      // Get the download URL after upload completes
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }

  // ─── Upload Post Image ────────────────────────────────────────────────────
  Future<String?> uploadPostImage(String postId, XFile imageFile) async {
    try {
      final ref =
          _storage.ref().child('post_images/$postId.jpg');

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
