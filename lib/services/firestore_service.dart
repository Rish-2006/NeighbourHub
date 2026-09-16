// lib/services/firestore_service.dart
//
// This service handles all reads and writes to our database.
// For this prototype, we are using in-memory mock data so it works
// perfectly across accounts without needing to set up Firebase!

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../models/help_request_model.dart';
import '../models/comment_model.dart';
import '../models/lost_found_model.dart';
import '../models/announcement_model.dart';
import '../data/mock_data.dart';

class FirestoreService {
  // In-memory global data
  static final List<UserModel> _users = List.from(MockData.users);
  static final List<PostModel> _posts = List.from(MockData.posts);
  static final List<CommentModel> _comments = [];
  static final List<EventModel> _events = List.from(MockData.events);
  static final List<NotificationModel> _notifications = List.from(MockData.notifications);
  static final List<HelpRequestModel> _helpRequests = List.from(MockData.helpRequests);
  
  static final List<LostFoundModel> _lostFound = [];
  static final List<AnnouncementModel> _announcements = [];

  static final StreamController<List<PostModel>> _postsController = StreamController.broadcast();
  static final StreamController<List<CommentModel>> _commentsController = StreamController.broadcast();
  static final StreamController<List<LostFoundModel>> _lostFoundController = StreamController.broadcast();
  static final StreamController<List<AnnouncementModel>> _announcementController = StreamController.broadcast();

  FirestoreService() {
    // Populate lost and found if empty
    if (_lostFound.isEmpty && MockData.lostFoundItems.isNotEmpty) {
      for (var item in MockData.lostFoundItems) {
        try {
          _lostFound.add(LostFoundModel.fromMap(item, item['id'] ?? ''));
        } catch (_) {}
      }
    }
  }

  void _notifyPosts() {
    final sorted = List<PostModel>.from(_posts);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _postsController.add(sorted);
  }
  
  void _notifyComments() {
    _commentsController.add(List.from(_comments));
  }

  // ─── User Operations ──────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> userExists(String userId) async {
    return _users.any((u) => u.id == userId);
  }

  Future<List<UserModel>> getNeighbours(String neighbourhood) async {
    return _users.where((u) => u.neighbourhood == neighbourhood).toList();
  }

  // ─── Post Operations ──────────────────────────────────────────────────────

  Stream<List<PostModel>> getPostsStream() async* {
    final sorted = List<PostModel>.from(_posts);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield sorted;
    yield* _postsController.stream;
  }

  Future<void> createPost(PostModel post) async {
    _posts.add(post);
    _notifyPosts();
  }

  Future<void> toggleLike(String postId, String userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index >= 0) {
      final post = _posts[index];
      final likedBy = List<String>.from(post.likedBy);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      _posts[index] = post.copyWith(
        likedBy: likedBy,
        likesCount: likedBy.length,
      );
      _notifyPosts();
    }
  }

  // ─── Comment Operations ───────────────────────────────────────────────────

  Stream<List<CommentModel>> getCommentsStream(String postId) async* {
    final postComments = _comments.where((c) => c.postId == postId).toList();
    postComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield postComments;
    
    yield* _commentsController.stream.map((allComments) {
      final filtered = allComments.where((c) => c.postId == postId).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  Future<void> addComment(CommentModel comment) async {
    _comments.add(comment);
    
    // Update post comments count
    final index = _posts.indexWhere((p) => p.id == comment.postId);
    if (index >= 0) {
      _posts[index] = _posts[index].copyWith(
        commentsCount: _posts[index].commentsCount + 1,
      );
      _notifyPosts();
    }
    
    _notifyComments();
  }

  // ─── Event Operations ─────────────────────────────────────────────────────

  Future<List<EventModel>> getEvents() async {
    final sorted = List<EventModel>.from(_events);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  Future<void> toggleEventParticipation(String eventId, String userId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index >= 0) {
      final event = _events[index];
      final participants = List<String>.from(event.participants);
      if (participants.contains(userId)) {
        participants.remove(userId);
      } else {
        participants.add(userId);
      }
      
      _events[index] = EventModel(
        id: event.id,
        title: event.title,
        description: event.description,
        emoji: event.emoji,
        date: event.date,
        location: event.location,
        createdBy: event.createdBy,
        createdByName: event.createdByName,
        participants: participants,
      );
    }
  }

  // ─── Notification Operations ──────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final userNotifs = _notifications.where((n) => n.userId == userId).toList();
    userNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userNotifs;
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final n = _notifications[index];
      _notifications[index] = NotificationModel(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
      );
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId) {
        final n = _notifications[i];
        _notifications[i] = NotificationModel(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
    }
  }

  // ─── Help Request Operations ──────────────────────────────────────────────

  Future<List<HelpRequestModel>> getHelpRequests() async {
    final sorted = List<HelpRequestModel>.from(_helpRequests);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<void> createHelpRequest(HelpRequestModel request) async {
    _helpRequests.add(request);
  }

  // ─── Issue Reporting ──────────────────────────────────────────────────────

  Future<void> reportIssue(Map<String, dynamic> issueData) async {
    debugPrint('Issue reported: $issueData');
  }

  // ─── Lost & Found Operations ──────────────────────────────────────────────

  Stream<List<LostFoundModel>> getLostFoundItemsStream() async* {
    yield _lostFound;
    yield* _lostFoundController.stream;
  }

  Future<void> createLostFoundItem(LostFoundModel item) async {
    _lostFound.add(item);
    _lostFoundController.add(List.from(_lostFound));
  }

  // ─── Announcement Operations ──────────────────────────────────────────────

  Stream<List<AnnouncementModel>> getAnnouncementsStream() async* {
    yield _announcements;
    yield* _announcementController.stream;
  }
}

