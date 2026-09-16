// lib/models/event_model.dart
//
// Represents a community event (Morning Run, Cleanup, etc.)
// Stored in Firestore's "events" collection.

class EventModel {
  final String id;
  final String title;
  final String description;
  final String emoji;         // Emoji icon for the event (e.g. "🏃")
  final DateTime date;        // Date and time of the event
  final String location;      // Where it takes place
  final String createdBy;     // User ID of who created it
  final String createdByName; // Creator's name
  final List<String> participants; // List of user IDs who joined

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.emoji = '📅',
    required this.date,
    required this.location,
    required this.createdBy,
    required this.createdByName,
    this.participants = const [],
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '📅',
      date: (map['date'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
          : DateTime.now(),
      location: map['location'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      participants: List<String>.from(map['participants'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'emoji': emoji,
      'date': date.millisecondsSinceEpoch,
      'location': location,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'participants': participants,
    };
  }

  // How many people are going
  int get participantCount => participants.length;

  // Check if a user is already joining this event
  bool isUserJoined(String userId) => participants.contains(userId);
}
