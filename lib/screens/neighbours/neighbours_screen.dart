// lib/screens/neighbours/neighbours_screen.dart
//
// Shows all neighbours in the community with search functionality.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/neighbour_card.dart';
import 'neighbour_profile_screen.dart';

class NeighboursScreen extends StatefulWidget {
  const NeighboursScreen({super.key});

  @override
  State<NeighboursScreen> createState() => _NeighboursScreenState();
}

class _NeighboursScreenState extends State<NeighboursScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _allNeighbours = [];
  List<UserModel> _filteredNeighbours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNeighbours();
  }

  Future<void> _loadNeighbours() async {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.currentUser?.uid ?? '';
    // Get the logged-in user's profile to find their neighbourhood
    final currentUser = await firestoreService.getUser(userId);
    final neighbourhood = currentUser?.neighbourhood ?? 'Green Valley Community';
    final neighbours = await firestoreService.getNeighbours(neighbourhood);
    if (mounted) {
      setState(() {
        // Exclude current user from neighbours list
        _allNeighbours = neighbours.where((u) => u.id != userId).toList();
        _filteredNeighbours = _allNeighbours;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredNeighbours = _allNeighbours;
      } else {
        _filteredNeighbours = _allNeighbours
            .where((n) =>
                n.name.toLowerCase().contains(query.toLowerCase()) ||
                n.bio.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neighbours'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search neighbours...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.tune_outlined),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Count ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredNeighbours.length} neighbours',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Neighbours List ─────────────────────────────────────────────
          Expanded(
            child: _filteredNeighbours.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No neighbours found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredNeighbours.length,
                    itemBuilder: (context, index) {
                      final neighbour = _filteredNeighbours[index];
                      return NeighbourCard(
                        neighbour: neighbour,
                        index: index,
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
                  ),
          ),
        ],
      ),
    );
  }
}
