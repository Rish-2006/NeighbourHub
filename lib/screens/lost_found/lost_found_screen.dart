// lib/screens/lost_found/lost_found_screen.dart
//
// Lost & Found section with Lost and Found tabs.
// IMPORTANT: Never displays phone numbers or private contact info.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../../models/lost_found_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReportItemDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String itemType = 'lost';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Report a Lost or Found Item',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              // Type selector
              Row(children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Lost'),
                    selected: itemType == 'lost',
                    selectedColor: AppTheme.errorColor.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.errorColor,
                    onSelected: (_) => setModalState(() => itemType = 'lost'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Found'),
                    selected: itemType == 'found',
                    selectedColor: AppTheme.successColor.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.successColor,
                    onSelected: (_) => setModalState(() => itemType = 'found'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Item name', hintText: 'e.g. Blue Backpack')),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Near park entrance')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final user = context.read<AuthService>().currentUser;
                  final item = LostFoundModel(
                    id: const Uuid().v4(),
                    type: itemType,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                    postedBy: user?.displayName ?? 'Neighbour',
                    postedById: user?.uid ?? '',
                    createdAt: DateTime.now(),
                  );
                  Navigator.pop(ctx);
                  try {
                    await context.read<FirestoreService>().createLostFoundItem(item);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ ${itemType == "lost" ? "Lost" : "Found"} item reported!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search_off_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Lost'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.find_in_page_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Found'),
                ],
              ),
            ),
          ],
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.grey600,
        ),
      ),
      body: StreamBuilder<List<LostFoundModel>>(
        stream: context.read<FirestoreService>().getLostFoundItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final lostItems = all.where((i) => i.type == 'lost').toList();
          final foundItems = all.where((i) => i.type == 'found').toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _LostFoundList(items: lostItems, type: 'lost'),
              _LostFoundList(items: foundItems, type: 'found'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Report Item'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _LostFoundList extends StatelessWidget {
  final List<LostFoundModel> items;
  final String type;

  const _LostFoundList({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLost = type == 'lost';
    final color = isLost ? AppTheme.errorColor : AppTheme.successColor;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLost ? Icons.search_off : Icons.find_in_page,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isLost ? 'No lost items reported' : 'No found items posted',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isResolved = item.isResolved;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isResolved
                            ? AppTheme.grey400.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isResolved ? 'RESOLVED' : isLost ? 'LOST' : 'FOUND',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isResolved ? AppTheme.grey600 : color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(item.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: isResolved ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.grey600),
                    const SizedBox(width: 3),
                    Text(item.location, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.grey600)),
                    const Spacer(),
                    const Icon(Icons.person_outline, size: 14, color: AppTheme.grey600),
                    const SizedBox(width: 3),
                    Text('By ${item.postedBy}', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.grey600)),
                  ],
                ),
                if (!isResolved) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('In-app messaging coming soon! Look for them on the Neighbours tab.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message_outlined, size: 16),
                    label: const Text('Contact through App'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      minimumSize: const Size(double.infinity, 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }
}
