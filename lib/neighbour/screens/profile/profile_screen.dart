// lib/screens/profile/profile_screen.dart
//
// Current user's profile showing their details and settings shortcuts.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'my_issues_screen.dart';
import 'my_posts_screen.dart';
import 'flat_number_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

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
              neighbourhood: 'Green Valley Community', // Mock default
              createdAt: DateTime.now(),
            );
        _isLoading = false;
      });
    }
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
            icon: const Icon(Icons.settings_outlined),
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

            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    backgroundImage: _currentUser!.photoUrl.isNotEmpty
                        ? NetworkImage(_currentUser!.photoUrl)
                        : null,
                    child: _currentUser!.photoUrl.isEmpty
                        ? Text(
                            _currentUser!.name.isNotEmpty
                                ? _currentUser!.name[0].toUpperCase()
                                : 'N',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          // Navigate to edit profile and wait for result
                          final updatedUser = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(user: _currentUser!),
                            ),
                          );
                          // If profile was updated, refresh the screen
                          if (updatedUser != null && updatedUser is UserModel) {
                            setState(() {
                              _currentUser = updatedUser;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(),
            
            const SizedBox(height: 16),
            
            // ── Name & Email ────────────────────────────────────────────────
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
            
            // ── Community Info ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                            const Icon(Icons.home_outlined, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Apartment / House',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

            // ── YOUR FLAT NUMBER ─────────────────────────────────────────────
            FlatNumberSection(userId: _currentUser!.id),

            const SizedBox(height: 16),
            
            // ── Menu Items ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.assignment_outlined,
                    title: 'My Issue Status',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyIssuesScreen()),
                      );
                    },
                  ).animate().fadeIn(delay: 200.ms),
                  
                  _ProfileMenuItem(
                    icon: Icons.article_outlined,
                    title: 'My Posts',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                      );
                    },
                  ).animate().fadeIn(delay: 250.ms),
                  
                  _ProfileMenuItem(
                    icon: Icons.event_outlined,
                    title: 'My Events',
                    onTap: () {},
                  ).animate().fadeIn(delay: 300.ms),
                  
                  _ProfileMenuItem(
                    icon: Icons.handshake_outlined,
                    title: 'My Help Requests',
                    onTap: () {},
                  ).animate().fadeIn(delay: 350.ms),
                  
                  _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
