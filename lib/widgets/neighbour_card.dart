// lib/widgets/neighbour_card.dart
//
// Card widget showing a neighbour's basic info in the Neighbours screen.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class NeighbourCard extends StatelessWidget {
  final UserModel neighbour;
  final VoidCallback? onViewProfile;
  final int index;

  const NeighbourCard({
    super.key,
    required this.neighbour,
    this.onViewProfile,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              backgroundImage: neighbour.photoUrl.isNotEmpty
                  ? NetworkImage(neighbour.photoUrl)
                  : null,
              child: neighbour.photoUrl.isEmpty
                  ? Text(
                      neighbour.name.isNotEmpty
                          ? neighbour.name[0].toUpperCase()
                          : 'N',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Name and Bio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    neighbour.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (neighbour.bio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      neighbour.bio,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (neighbour.apartment.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 13,
                          color: AppTheme.primaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          neighbour.apartment,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // View Profile Button
            TextButton(
              onPressed: onViewProfile,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'View',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 300.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }
}
