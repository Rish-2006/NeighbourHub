// lib/services/firestore_service.dart
//
// This service handles all reads and writes to our database.
// For this prototype, we are using in-memory mock data so it works
// perfectly across accounts without needing to set up Firebase!

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../models/help_request_model.dart';
import '../models/connection_request_model.dart';
import '../models/connection_model.dart';
import '../models/comment_model.dart';
import '../models/lost_found_model.dart';
import '../models/announcement_model.dart';
import '../data/mock_data.dart';

class FirestoreService {
  // In-memory global data (non-user features still use mock data)
  static final List<CommentModel> _comments = [];
  static final List<EventModel> _events = List.from(MockData.events);
  static final List<NotificationModel> _notifications = List.from(MockData.notifications);
  static final List<HelpRequestModel> _helpRequests = List.from(MockData.helpRequests);
  
  static final List<LostFoundModel> _lostFound = [];
  static final List<AnnouncementModel> _announcements = [];

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

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  void _notifyComments() {
    _commentsController.add(List.from(_comments));
  }

  // ─── User Operations ──────────────────────────────────────────────────────

  /// Saves (upserts) a user document into Firestore.
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  /// Fetches a single user by their UID from Firestore.
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('getUser error: $e');
      return null;
    }
  }

  /// Checks whether a user document exists in Firestore.
  Future<bool> userExists(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists;
  }

  /// Gets all users in the same neighbourhood — used for the Members list.
  /// Falls back to all users if none match the neighbourhood (handles empty neighbourhood field).
  Future<List<UserModel>> getNeighbours(String neighbourhood) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      if (neighbourhood.isNotEmpty) {
        snap = await _db
            .collection('users')
            .where('neighbourhood', isEqualTo: neighbourhood)
            .get();
      } else {
        snap = await _db.collection('users').get();
      }
      return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('getNeighbours error: $e');
      return [];
    }
  }

  /// Gets ALL registered users — for the Members screen when neighbourhood is not set.
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snap = await _db.collection('users').get();
      return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('getAllUsers error: $e');
      return [];
    }
  }

  /// Real-time stream of ALL registered users
  Stream<List<UserModel>> getAllUsersStream() {
    return _db.collection('users').snapshots().map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  // ─── Post Operations ──────────────────────────────────────────────────────

  Stream<List<PostModel>> getPostsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> createPost(PostModel post) async {
    await _db.collection('posts').doc(post.id).set(post.toMap()).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout. Please ensure Firestore Database is enabled in your Firebase Console!'),
    );
  }

  Future<void> toggleLike(String postId, String userId) async {
    final docRef = _db.collection('posts').doc(postId);
    final docSnap = await docRef.get();
    if (!docSnap.exists) return;
    
    final post = PostModel.fromMap(docSnap.data()!, docSnap.id);
    final likedBy = List<String>.from(post.likedBy);
    
    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
    
    await docRef.update({
      'likedBy': likedBy,
      'likesCount': likedBy.length,
    });
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
    
    // Update post comments count in Firestore
    final docRef = _db.collection('posts').doc(comment.postId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final post = PostModel.fromMap(docSnap.data()!, docSnap.id);
      await docRef.update({
        'commentsCount': post.commentsCount + 1,
      });
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

  // ─── Connection Methods ──────────────────────────────────────────────────

  Future<void> sendConnectionRequest(UserModel sender, UserModel receiver) async {
    if (sender.id == receiver.id) return; // Prevent self request

    // Check if pending request exists
    final q1 = await _db.collection('connection_requests')
        .where('senderId', isEqualTo: sender.id)
        .where('receiverId', isEqualTo: receiver.id)
        .where('status', isEqualTo: 'pending')
        .get();
    
    final q2 = await _db.collection('connection_requests')
        .where('senderId', isEqualTo: receiver.id)
        .where('receiverId', isEqualTo: sender.id)
        .where('status', isEqualTo: 'pending')
        .get();

    if (q1.docs.isNotEmpty || q2.docs.isNotEmpty) return;

    // Check if connected
    final ids = [sender.id, receiver.id]..sort();
    final connectionId = '${ids[0]}_${ids[1]}';
    final connDoc = await _db.collection('connections').doc(connectionId).get();
    if (connDoc.exists) return;

    final requestId = '${sender.id}_${receiver.id}';
    final request = ConnectionRequestModel(
      id: requestId,
      senderId: sender.id,
      senderName: sender.name,
      receiverId: receiver.id,
      receiverName: receiver.name,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _db.collection('connection_requests').doc(requestId).set(request.toMap());
  }

  Future<void> acceptConnectionRequest(ConnectionRequestModel request) async {
    // 1. Update the request status
    await _db.collection('connection_requests').doc(request.id).update({
      'status': 'accepted',
    });
    
    // 2. Create the connection document
    final ids = [request.senderId, request.receiverId]..sort();
    final connectionId = '${ids[0]}_${ids[1]}';
    
    final connection = ConnectionModel(
      id: connectionId,
      user1Id: ids[0],
      user2Id: ids[1],
      createdAt: DateTime.now(),
    );
    
    await _db.collection('connections').doc(connectionId).set(connection.toMap());
  }

  Future<void> rejectConnectionRequest(String requestId) async {
    await _db.collection('connection_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Stream<List<ConnectionRequestModel>> getPendingRequestsStream(String currentUserId) {
    return _db
        .collection('connection_requests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  Stream<List<ConnectionRequestModel>> getSentRequestsStream(String currentUserId) {
    return _db
        .collection('connection_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<String>> getConnectedUserIdsStream(String currentUserId) {
    return _db
        .collection('connections')
        .where(
          Filter.or(
            Filter('user1Id', isEqualTo: currentUserId),
            Filter('user2Id', isEqualTo: currentUserId),
          ),
        )
        .snapshots()
        .map((snapshot) {
      final List<String> connectedIds = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['user1Id'] == currentUserId) {
          connectedIds.add(data['user2Id'] as String);
        } else {
          connectedIds.add(data['user1Id'] as String);
        }
      }
      return connectedIds;
    });
  }
}

