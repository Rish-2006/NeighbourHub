// lib/screens/profile/profile_screen.dart
//
// Current user's profile showing their details and settings shortcuts.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'flat_number_section.dart';
import 'my_issues_screen.dart';
import 'my_posts_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = context.read<AuthService>();
    final firebaseUser = authService.currentUser;

    if (firebaseUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final firestoreService = context.read<FirestoreService>();
    final user = await firestoreService.getUser(firebaseUser.uid);

    if (mounted) {
      setState(() {
        _currentUser = user ??
            UserModel(
              id: firebaseUser.uid,
              name: firebaseUser.displayName ?? 'Neighbour',
              email: firebaseUser.email ?? '',
              photoUrl: firebaseUser.photoURL ?? '',
              neighbourhood: 'Green Valley Community',
              createdAt: DateTime.now(),
            );
        _isLoading = false;
      });
    }
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        _currentUser!.name.isNotEmpty
            ? _currentUser!.name[0].toUpperCase()
            : 'N',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final hasPhoto = _currentUser?.photoUrl.isNotEmpty == true;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Circular Avatar (kept at original radius 50 / 100x100) ───────
          GestureDetector(
            onTap: _isUploadingImage ? null : _showImageSourceActionSheet,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: _currentUser!.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
          ),

          // ── Loading indicator while uploading ─────────────────────────────
          if (_isUploadingImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),

          // ── Camera/Edit Overlay Badge at bottom-right corner ──────────────
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _showImageSourceActionSheet,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.darkBg,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(7),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  void _showImageSourceActionSheet() {
    if (_isUploadingImage) return;

    final hasPhoto = _currentUser?.photoUrl.isNotEmpty == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Take photo
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Use device camera',
                    style: TextStyle(
                      color: AppTheme.darkSubtext,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadProfileImage(ImageSource.camera);
                  },
                ),

                // Option 2: Choose from gallery
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Select existing photo',
                    style: TextStyle(
                      color: AppTheme.darkSubtext,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadProfileImage(ImageSource.gallery);
                  },
                ),

                // Option 3: Remove current photo
                if (hasPhoto) ...[
                  const Divider(height: 16, color: AppTheme.darkBorder),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorColor,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Remove current photo',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _removeProfileImage();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    final authService = context.read<AuthService>();
    final firebaseUser = authService.currentUser;

    if (firebaseUser == null ||
        _currentUser == null ||
        firebaseUser.uid != _currentUser!.id) {
      _showError('You can only update your own profile picture.');
      return;
    }

    try {
      final storageService = context.read<StorageService>();
      final firestoreService = context.read<FirestoreService>();

      final XFile? pickedFile = await storageService.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      // User cancelled picker
      if (pickedFile == null) return;

      // Validate file extension
      final fileName = pickedFile.name.toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      final hasValidExtension =
          validExtensions.any((ext) => fileName.endsWith(ext));
      if (!hasValidExtension) {
        _showError(
            'Unsupported file type. Please select a JPG, PNG, or WEBP image.');
        return;
      }

      // Read bytes & validate size limit (max 5 MB)
      final imageBytes = await pickedFile.readAsBytes();
      const maxSizeBytes = 5 * 1024 * 1024;
      if (imageBytes.lengthInBytes > maxSizeBytes) {
        final sizeMb =
            (imageBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
        _showError(
            'Image size ($sizeMb MB) exceeds the 5 MB limit. Please select a smaller photo.');
        return;
      }

      setState(() => _isUploadingImage = true);

      // Upload to Firebase Storage
      final extension =
          fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final downloadUrl = await storageService.uploadProfileImage(
        userId: firebaseUser.uid,
        imageBytes: imageBytes,
        extension: extension,
      );

      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception(
            'Failed to get download URL from Firebase Storage.');
      }

      // Store download URL in Firestore user document
      await firestoreService.updateUserProfilePhoto(
          firebaseUser.uid, downloadUrl);

      // Update Firebase Auth profile photo URL
      try {
        await firebaseUser.updatePhotoURL(downloadUrl);
      } catch (authErr) {
        debugPrint(
            'Firebase Auth photoURL update error (non-fatal): $authErr');
      }

      if (mounted) {
        setState(() {
          _currentUser = _currentUser!.copyWith(photoUrl: downloadUrl);
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showError(
            'Upload failed. Please check your internet connection and try again.');
      }
    }
  }

  Future<void> _removeProfileImage() async {
    final authService = context.read<AuthService>();
    final firebaseUser = authService.currentUser;

    if (firebaseUser == null ||
        _currentUser == null ||
        firebaseUser.uid != _currentUser!.id) {
      _showError('You can only update your own profile picture.');
      return;
    }

    final currentPhotoUrl = _currentUser!.photoUrl;
    if (currentPhotoUrl.isEmpty) return;

    setState(() => _isUploadingImage = true);

    try {
      final storageService = context.read<StorageService>();
      final firestoreService = context.read<FirestoreService>();

      // 1. Delete image file from Firebase Storage
      await storageService.deleteProfileImage(
        userId: firebaseUser.uid,
        photoUrl: currentPhotoUrl,
      );

      // 2. Clear photoUrl in Firestore user document
      await firestoreService.updateUserProfilePhoto(firebaseUser.uid, '');

      // 3. Clear Firebase Auth user photoURL
      try {
        await firebaseUser.updatePhotoURL(null);
      } catch (authErr) {
        debugPrint(
            'Firebase Auth photoURL clear error (non-fatal): $authErr');
      }

      if (mounted) {
        setState(() {
          _currentUser = _currentUser!.copyWith(photoUrl: '');
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed.'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing profile image: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showError('Failed to remove profile picture. Please try again.');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () async {
              final updatedUser = await Navigator.push<UserModel>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfileScreen(user: _currentUser!),
                ),
              );
              if (updatedUser != null && mounted) {
                setState(() => _currentUser = updatedUser);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Avatar ────────────────────────────────────────────────────────
            _buildAvatar(),

            const SizedBox(height: 12),

            // ── Name & Email ──────────────────────────────────────────────────
            Text(
              _currentUser!.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 100.ms),

            Text(
              _currentUser!.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 24),

            // ── Community Info ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                Text(
                                  _currentUser!.neighbourhood.isNotEmpty
                                      ? _currentUser!.neighbourhood
                                      : 'Not set',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (_currentUser!.apartment.isNotEmpty) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.home_outlined,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Apartment / House',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Text(
                                    _currentUser!.apartment,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // ── YOUR FLAT NUMBER ──────────────────────────────────────────────
            FlatNumberSection(userId: _currentUser!.id),

            const SizedBox(height: 16),

            // ── Menu Items ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile Details',
                    onTap: () async {
                      final updatedUser = await Navigator.push<UserModel>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProfileScreen(user: _currentUser!),
                        ),
                      );
                      if (updatedUser != null && mounted) {
                        setState(() => _currentUser = updatedUser);
                      }
                    },
                  ).animate().fadeIn(delay: 150.ms),

                  _ProfileMenuItem(
                    icon: Icons.assignment_outlined,
                    title: 'My Issue Status',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyIssuesScreen()),
                      );
                    },
                  ).animate().fadeIn(delay: 200.ms),

                  _ProfileMenuItem(
                    icon: Icons.article_outlined,
                    title: 'My Posts',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyPostsScreen()),
                      );
                    },
                  ).animate().fadeIn(delay: 250.ms),

                  _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
