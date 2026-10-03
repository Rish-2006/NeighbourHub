// lib/neighbour/screens/admin/admin_events_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  // ── Add Event ─────────────────────────────────────────────────────────────
  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkCard,
              title: const Text('Add Upcoming Event', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Event Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) setState(() => selectedDate = d);
                            },
                            child: Text(selectedDate == null
                                ? 'Select Date'
                                : DateFormat('dd MMM yyyy').format(selectedDate!)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (t != null) setState(() => selectedTime = t);
                            },
                            child: Text(selectedTime == null
                                ? 'Select Time'
                                : selectedTime!.format(context)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.darkSubtext)),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        selectedDate == null ||
                        selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    final combinedDate = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    final newEvent = EventModel(
                      id: '',
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      date: combinedDate,
                      location: 'Community Center', // Optional
                      createdBy: 'admin',
                      createdByName: 'Admin',
                    );

                    await context.read<FirestoreService>().createEvent(newEvent);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: const Text('Create Event', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully.'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  // ── Delete Event ──────────────────────────────────────────────────────────
  Future<void> _confirmDelete(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Event?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete:\n\n${event.title}\n\nThis will also remove all its registrations.', style: const TextStyle(color: AppTheme.darkSubtext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FirestoreService>().deleteEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully.'), backgroundColor: AppTheme.darkCard),
      );
    }
  }

  // ── View Registrations ────────────────────────────────────────────────────
  void _viewRegistrations(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 16),
                Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${DateFormat('dd MMM yyyy').format(event.date)} • ${DateFormat('h:mm a').format(event.date)}', style: const TextStyle(color: AppTheme.primaryColor)),
                const Divider(color: AppTheme.darkBorder),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: context.read<FirestoreService>().getEventRegistrationsStream(event.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final registrations = snapshot.data ?? [];
                      if (registrations.isEmpty) {
                        return const Center(child: Text('No registrations yet.'));
                      }
                      return ListView.builder(
                        controller: controller,
                        itemCount: registrations.length,
                        itemBuilder: (context, index) {
                          final reg = registrations[index];
                          final regDate = (reg['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: AppTheme.primaryColor),
                            ),
                            title: Text(reg['userName'] ?? 'Unknown User', style: const TextStyle(color: Colors.white)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(reg['flatNumber'] != null && reg['flatNumber'].toString().isNotEmpty ? 'Flat ${reg['flatNumber']}' : 'No flat specified', style: const TextStyle(color: AppTheme.darkSubtext)),
                                Text(reg['userEmail'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.darkSubtext)),
                              ],
                            ),
                            trailing: Text(
                              'Registered:\n${DateFormat('dd MMM yyyy').format(regDate)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _showAddEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Event'),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EventModel>>(
            stream: context.read<FirestoreService>().getEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const Center(child: Text('No upcoming events'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    color: AppTheme.darkBg,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${DateFormat('dd MMM yyyy').format(event.date)} • ${DateFormat('h:mm a').format(event.date)}', style: const TextStyle(color: AppTheme.darkSubtext)),
                          const SizedBox(height: 8),
                          Text('Registered: ${event.participantCount}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _viewRegistrations(event),
                                  child: const Text('View Registrations'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _confirmDelete(event),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  side: const BorderSide(color: AppTheme.errorColor),
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
