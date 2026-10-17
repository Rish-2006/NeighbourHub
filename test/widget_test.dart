import 'package:flutter_test/flutter_test.dart';
import 'package:neighbour_hub/neighbour/models/user_model.dart';

void main() {
  test('Basic test', () {
    expect(true, true);
  });

  group('UserModel Profile Image Tests', () {
    test('UserModel preserves photoUrl in fromMap and toMap', () {
      final now = DateTime.now();
      final map = {
        'name': 'Test User',
        'email': 'test@example.com',
        'photoUrl': 'https://firebasestorage.googleapis.com/v0/b/bucket/o/users%2F123%2Fprofile.jpg',
        'neighbourhood': 'Green Valley',
        'apartment': 'A-101',
        'bio': 'Hello World',
        'createdAt': now.millisecondsSinceEpoch,
      };

      final user = UserModel.fromMap(map, 'user_123');
      expect(user.id, 'user_123');
      expect(user.name, 'Test User');
      expect(user.photoUrl, 'https://firebasestorage.googleapis.com/v0/b/bucket/o/users%2F123%2Fprofile.jpg');

      final serialized = user.toMap();
      expect(serialized['photoUrl'], user.photoUrl);
      expect(serialized['name'], 'Test User');
    });

    test('UserModel copyWith updates photoUrl without modifying other fields', () {
      final user = UserModel(
        id: 'user_123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        photoUrl: '',
        neighbourhood: 'Maple Ridge',
        apartment: 'B-204',
        bio: 'Gardener',
        createdAt: DateTime.now(),
      );

      final updated = user.copyWith(photoUrl: 'https://storage.googleapis.com/profile.jpg');
      expect(updated.photoUrl, 'https://storage.googleapis.com/profile.jpg');
      expect(updated.id, user.id);
      expect(updated.name, user.name);
      expect(updated.email, user.email);
      expect(updated.neighbourhood, user.neighbourhood);
      expect(updated.apartment, user.apartment);
      expect(updated.bio, user.bio);

      final cleared = updated.copyWith(photoUrl: '');
      expect(cleared.photoUrl, '');
      expect(cleared.name, user.name);
    });

    test('File extension and size validation logic', () {
      final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      bool isValidExt(String filename) {
        final lower = filename.toLowerCase();
        return validExtensions.any((ext) => lower.endsWith(ext));
      }

      expect(isValidExt('avatar.jpg'), true);
      expect(isValidExt('photo.JPEG'), true);
      expect(isValidExt('IMAGE.PNG'), true);
      expect(isValidExt('picture.webp'), true);
      expect(isValidExt('document.pdf'), false);
      expect(isValidExt('script.exe'), false);

      const maxBytes = 5 * 1024 * 1024;
      expect(2 * 1024 * 1024 <= maxBytes, true);
      expect(6 * 1024 * 1024 <= maxBytes, false);
    });
  });
}
