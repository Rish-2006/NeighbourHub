// lib/models/post_model.dart
//
// Represents a community post (like a Facebook post, but for the neighbourhood).
// Stored in Firestore's "posts" collection.

// The type of post - helps categorize it in the feed
enum PostType {
  general,
  helpRequest,
  lostFound,
  recommendation,
  announcement,
  safety,
}

// Helper extension to get display names and icons for post types
extension PostTypeExtension on PostType {
  // Human-readable name shown in the UI
  String get displayName {
    switch (this) {
      case PostType.general:      return 'General';
      case PostType.helpRequest:  return 'Help Request';
      case PostType.lostFound:    return 'Lost & Found';
      case PostType.recommendation: return 'Recommendation';
      case PostType.announcement: return 'Announcement';
      case PostType.safety:       return 'Safety';
    }
  }

  // The string stored in Firestore
  String get value {
    switch (this) {
      case PostType.general:      return 'general';
      case PostType.helpRequest:  return 'helpRequest';
      case PostType.lostFound:    return 'lostFound';
      case PostType.recommendation: return 'recommendation';
      case PostType.announcement: return 'announcement';
      case PostType.safety:       return 'safety';
    }
  }

  // Creates a PostType from the stored Firestore string
  static PostType fromString(String value) {
    switch (value) {
      case 'helpRequest':    return PostType.helpRequest;
      case 'lostFound':      return PostType.lostFound;
      case 'recommendation': return PostType.recommendation;
      case 'announcement':   return PostType.announcement;
      case 'safety':         return PostType.safety;
      default:               return PostType.general;
    }
  }
}

class PostModel {
  final String id;
  final String userId;      // Who created this post
  final String userName;    // Their name (stored so we don't need to look it up)
  final String userPhoto;   // Their photo URL
  final PostType type;      // What kind of post it is
  final String title;       // Short title
  final String description; // Full post body
  final String imageUrl;    // Optional image attached to the post
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy; // List of user IDs who liked this post

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl = '',
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
  });

  // Creates a PostModel from a Firestore document
  factory PostModel.fromMap(Map<String, dynamic> map, String docId) {
    return PostModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Unknown',
      userPhoto: map['userPhoto'] as String? ?? '',
      type: PostTypeExtension.fromString(map['type'] as String? ?? 'general'),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      createdAt: (map['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      likesCount: map['likesCount'] as int? ?? 0,
      commentsCount: map['commentsCount'] as int? ?? 0,
      likedBy: List<String>.from(map['likedBy'] as List? ?? []),
    );
  }

  // Converts this model to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'type': type.value,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
    };
  }

  PostModel copyWith({
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      userName: userName,
      userPhoto: userPhoto,
      type: type,
      title: title,
      description: description,
      imageUrl: imageUrl,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}
