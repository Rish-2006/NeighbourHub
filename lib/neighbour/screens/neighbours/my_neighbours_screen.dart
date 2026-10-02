// lib/screens/neighbours/my_neighbours_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neighbour_card.dart';
import 'neighbour_profile_screen.dart';

class MyNeighboursScreen extends StatelessWidget {
  const MyNeighboursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Neighbours'),
      ),
      body: StreamBuilder<List<String>>(
        stream: firestoreService.getConnectedUserIdsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading neighbours:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          final connectedIds = snapshot.data ?? [];

          if (connectedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No neighbours yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send requests to connect with people.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            );
          }

          // We need to fetch the actual UserModels for these IDs.
          // Since Firestore limits 'whereIn' to 10 elements, we might just fetch
          // all users in the neighbourhood and filter locally for simplicity,
          // OR we can do FutureBuilder to get them.
          return FutureBuilder<List<UserModel>>(
            future: _fetchUsers(firestoreService, connectedIds),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final neighbours = userSnapshot.data ?? [];

              return ListView.builder(
                itemCount: neighbours.length,
                itemBuilder: (context, index) {
                  final neighbour = neighbours[index];
                  return NeighbourCard(
                    neighbour: neighbour,
                    index: index,
                    connectionStatus: 'connected', // They are connected
                    onViewProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NeighbourProfileScreen(
                            neighbour: neighbour,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<UserModel>> _fetchUsers(FirestoreService firestore, List<String> ids) async {
    final List<UserModel> users = [];
    for (String id in ids) {
      final user = await firestore.getUser(id);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }
}
