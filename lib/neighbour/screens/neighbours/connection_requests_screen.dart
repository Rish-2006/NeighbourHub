// lib/screens/neighbours/connection_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/connection_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class ConnectionRequestsScreen extends StatelessWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Requests'),
      ),
      body: StreamBuilder<List<ConnectionRequestModel>>(
        stream: firestoreService.getPendingRequestsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading requests:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          request.senderName.isNotEmpty ? request.senderName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.senderName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'wants to connect with you',
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await firestoreService.acceptConnectionRequest(request);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(70, 30),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Accept', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            onPressed: () async {
                              await firestoreService.rejectConnectionRequest(request.id);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(70, 30),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
