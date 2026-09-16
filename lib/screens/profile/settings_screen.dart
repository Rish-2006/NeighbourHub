// lib/screens/profile/settings_screen.dart
//
// Settings screen for dark mode toggle, app info, and logout.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../main.dart'; // To access ThemeController

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of NeighbourHub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthService>().signOut();
              Navigator.pop(context); // Go back to root (which handles routing to login)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // ── Appearance ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'APPEARANCE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme throughout the app'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: themeController.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeController.toggleTheme(value);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ── Account ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ACCOUNT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Push Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy & Security'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ── About ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ABOUT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About NeighbourHub'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'NeighbourHub',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        width: 50, height: 50,
                        color: AppTheme.primaryColor,
                        child: const Icon(Icons.house, color: Colors.white),
                      ),
                      children: [
                        const Text('Your neighbourhood, connected.'),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // ── Logout ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
