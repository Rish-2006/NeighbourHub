// lib/screens/community/events_screen.dart
//
// Full events listing with RSVP functionality.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  void _toggleJoin(EventModel event, String userId) async {
    await context.read<FirestoreService>().toggleEventParticipation(event.id, userId);
    if (!mounted) return;
    final isJoined = event.participants.contains(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !isJoined
              ? 'You\'re going to "${event.title}"! 🎉'
              : 'You\'ve left "${event.title}".',
        ),
        backgroundColor:
            !isJoined ? AppTheme.successColor : AppTheme.grey600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Events'),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: context.read<FirestoreService>().getEvents().asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming events',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return EventCard(
                event: events[index],
                currentUserId: userId,
                index: index,
                onJoin: () => _toggleJoin(events[index], userId),
              );
            },
          );
        },
      ),
    );
  }
}
