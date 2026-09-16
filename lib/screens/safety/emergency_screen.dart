// lib/screens/safety/emergency_screen.dart
//
// Emergency & Safety screen.
//
// IMPORTANT DISCLAIMER:
// This app is NOT an emergency service.
// The emergency buttons here only show information and guide the user
// to contact appropriate official emergency services.
// They do NOT replace calling 100 (Police), 108 (Ambulance), or 101 (Fire).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Safety'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Important Disclaimer Banner ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emergency,
                          color: AppTheme.errorColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '🚨 IMPORTANT',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For immediate danger to life or property, '
                    'ALWAYS contact your local official emergency services first. '
                    'This app is a community tool — it is NOT an emergency service.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorColor.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── Emergency Numbers ─────────────────────────────────────────
            Text(
              'Emergency Numbers (India)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            ..._emergencyNumbers.asMap().entries.map((entry) {
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item['emoji'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(
                    item['name'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    item['description'] as String,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['number'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: item['color'] as Color,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (150 + entry.key * 60).ms);
            }),

            const SizedBox(height: 20),

            // ── Community Actions ─────────────────────────────────────────
            Text(
              'Community Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 4),
            Text(
              'For non-emergency community issues only.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ).animate().fadeIn(delay: 430.ms),
            const SizedBox(height: 12),

            // Report Safety Issue button
            _ActionButton(
              icon: Icons.report_problem_outlined,
              label: 'Report a Safety Issue',
              subtitle: 'Broken lights, unsafe roads, suspicious activity',
              color: AppTheme.warningColor,
              onTap: () => Navigator.pushNamed(context, '/report-issue'),
            ).animate().fadeIn(delay: 460.ms),

            const SizedBox(height: 10),

            // Community Alert button
            _ActionButton(
              icon: Icons.notifications_active_outlined,
              label: 'Send Community Alert',
              subtitle: 'Notify your neighbours about something important',
              color: AppTheme.infoColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Community Alert feature coming soon! For now, create an Announcement post.'),
                  ),
                );
              },
            ).animate().fadeIn(delay: 490.ms),

            const SizedBox(height: 24),

            // ── Safety Tips ────────────────────────────────────────────────
            Text(
              'Safety Tips',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 520.ms),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _safetyTips.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ).animate().fadeIn(delay: 560.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────
const _emergencyNumbers = [
  {
    'emoji': '🚔',
    'name': 'Police',
    'description': 'Crime, theft, violence',
    'number': '100',
    'color': AppTheme.infoColor,
  },
  {
    'emoji': '🚑',
    'name': 'Ambulance',
    'description': 'Medical emergency',
    'number': '108',
    'color': AppTheme.errorColor,
  },
  {
    'emoji': '🚒',
    'name': 'Fire Brigade',
    'description': 'Fire emergency',
    'number': '101',
    'color': Color(0xFFFF6B35),
  },
  {
    'emoji': '🆘',
    'name': 'Disaster Management',
    'description': 'Natural disasters',
    'number': '1077',
    'color': AppTheme.warningColor,
  },
];

const _safetyTips = [
  'Always lock your door when leaving your apartment.',
  'Report suspicious strangers near the premises to security.',
  'Keep a note of emergency contact numbers.',
  'Do not let unknown visitors in without verification.',
  'Park your vehicle only in designated areas.',
  'Report damaged street lights or broken gates immediately.',
];
