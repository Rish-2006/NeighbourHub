// lib/screens/community/announcements_screen.dart
//
// Full list of community announcements.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/announcement_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: context.read<FirestoreService>().getAnnouncementsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final announcements = snapshot.data ?? [];
          if (announcements.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = announcements[index];
              return Card(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign,
                              color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'OFFICIAL ANNOUNCEMENT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        a.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppTheme.grey600),
                          const SizedBox(width: 4),
                          Text(
                            a.postedBy,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.grey600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppTheme.grey600),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(a.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}
