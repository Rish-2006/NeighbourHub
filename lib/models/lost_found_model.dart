// lib/models/lost_found_model.dart

class LostFoundModel {
  final String id;
  final String type; // 'lost' or 'found'
  final String title;
  final String description;
  final String location;
  final String postedBy;
  final String postedById;
  final DateTime createdAt;
  final bool isResolved;

  const LostFoundModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.postedBy,
    required this.postedById,
    required this.createdAt,
    this.isResolved = false,
  });

  factory LostFoundModel.fromMap(Map<String, dynamic> map, String docId) {
    return LostFoundModel(
      id: docId,
      type: map['type'] as String? ?? 'lost',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      postedBy: map['postedBy'] as String? ?? 'Unknown',
      postedById: map['postedById'] as String? ?? '',
      createdAt: (map['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      isResolved: map['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'location': location,
      'postedBy': postedBy,
      'postedById': postedById,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isResolved': isResolved,
    };
  }
}
