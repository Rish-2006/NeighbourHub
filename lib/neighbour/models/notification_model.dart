// lib/models/notification_model.dart
//
// Represents an in-app notification.
// E.g. "Priya commented on your post", "New event in your community"

enum NotificationType {
  like,
  comment,
  event,
  announcement,
  helpResponse,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.like:         return 'like';
      case NotificationType.comment:      return 'comment';
      case NotificationType.event:        return 'event';
      case NotificationType.announcement: return 'announcement';
      case NotificationType.helpResponse: return 'helpResponse';
      case NotificationType.general:      return 'general';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'like':         return NotificationType.like;
      case 'comment':      return NotificationType.comment;
      case 'event':        return NotificationType.event;
      case 'announcement': return NotificationType.announcement;
      case 'helpResponse': return NotificationType.helpResponse;
      default:             return NotificationType.general;
    }
  }

  // Icon to show for this notification type
  String get emoji {
    switch (this) {
      case NotificationType.like:         return '❤️';
      case NotificationType.comment:      return '💬';
      case NotificationType.event:        return '📅';
      case NotificationType.announcement: return '📢';
      case NotificationType.helpResponse: return '🤝';
      case NotificationType.general:      return '🔔';
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;    // Who this notification is for
  final String title;     // Short heading
  final String message;   // Full message
  final NotificationType type;
  final bool isRead;      // Has the user seen this?
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: NotificationTypeExtension.fromString(
          map['type'] as String? ?? 'general'),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.value,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
