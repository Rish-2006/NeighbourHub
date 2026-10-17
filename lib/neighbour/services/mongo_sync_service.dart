// lib/neighbour/services/mongo_sync_service.dart
//
// Synchronizes data safely and idempotently from Flutter/Firestore
// to the local Node.js + Express + MongoDB backend.
//
// Automatically attaches the current user's Firebase ID token for authentication.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/comment_model.dart';
import '../models/lost_found_model.dart';
import '../models/notification_model.dart';
import '../models/connection_request_model.dart';
import '../models/connection_model.dart';
import '../models/announcement_model.dart';

class MongoSyncService {
  static final MongoSyncService instance = MongoSyncService();

  final String baseUrl;

  MongoSyncService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConstants.backendBaseUrl;

  /// Retrieves a valid Firebase ID token for the currently authenticated user
  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      debugPrint('[MongoSyncService] Error obtaining ID token: $e');
      return null;
    }
  }

  /// Converts Timestamp, FieldValue, and DateTime objects into serializable JSON representations
  Map<String, dynamic> _cleanPayload(Map<String, dynamic> raw) {
    final Map<String, dynamic> result = {};
    raw.forEach((key, value) {
      result[key] = _cleanValue(value);
    });
    return result;
  }

  dynamic _cleanValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is DateTime) {
      return value.toIso8601String();
    } else if (value is FieldValue) {
      return DateTime.now().toIso8601String();
    } else if (value is Map) {
      return _cleanPayload(Map<String, dynamic>.from(value));
    } else if (value is List) {
      return value.map((item) => _cleanValue(item)).toList();
    } else {
      return value;
    }
  }

  /// Checks the backend health endpoint (public, unauthenticated)
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(Uri.parse('$baseUrl/health'));
      final response = await request.close();

      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[MongoSyncService] Health check unreachable: $e');
    }
    return null;
  }

  /// Generic batch sync method for any collection
  Future<bool> syncBatch({
    required String collection,
    required List<Map<String, dynamic>> documents,
  }) async {
    if (documents.isEmpty) return true;

    final token = await _getIdToken();
    if (token == null) {
      debugPrint('[MongoSyncService] Cannot sync $collection: No authenticated session');
      return false;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final uri = Uri.parse('$baseUrl/api/sync/batch');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');

      final cleanedDocs = documents.map((d) => _cleanPayload(d)).toList();
      final payload = jsonEncode({
        'collection': collection,
        'documents': cleanedDocs,
      });

      request.write(payload);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        debugPrint('[MongoSyncService] Batch sync success for $collection (${documents.length} docs)');
        return true;
      } else {
        debugPrint('[MongoSyncService] Batch sync failed for $collection (${response.statusCode}): $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('[MongoSyncService] Batch sync exception for $collection: $e');
      return false;
    }
  }

  /// Generic single document sync
  Future<bool> syncDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    return await syncBatch(collection: collection, documents: [data]);
  }

  /// Generic delete endpoint
  Future<bool> deleteDocument({
    required String collection,
    required String id,
  }) async {
    final token = await _getIdToken();
    if (token == null) return false;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse('$baseUrl/api/sync/delete');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');

      final payload = jsonEncode({
        'collection': collection,
        'id': id,
      });
      request.write(payload);

      final response = await request.close();
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[MongoSyncService] Delete exception for $collection/$id: $e');
      return false;
    }
  }

  // ─── Typed Sync Methods for All Collections ────────────────────────────────

  Future<bool> syncUser(UserModel user) async {
    final doc = user.toMap()..['id'] = user.id;
    return await syncDocument(collection: 'users', data: doc);
  }

  Future<bool> deleteUser(String userId) async {
    return await deleteDocument(collection: 'users', id: userId);
  }

  Future<bool> syncPost(PostModel post) async {
    final doc = post.toMap()..['id'] = post.id;
    return await syncDocument(collection: 'posts', data: doc);
  }

  Future<bool> deletePost(String postId) async {
    return await deleteDocument(collection: 'posts', id: postId);
  }

  Future<bool> syncComment(CommentModel comment) async {
    final doc = comment.toMap()..['id'] = comment.id;
    return await syncDocument(collection: 'comments', data: doc);
  }

  Future<bool> syncEvent(EventModel event) async {
    final doc = event.toMap()..['id'] = event.id;
    return await syncDocument(collection: 'events', data: doc);
  }

  Future<bool> deleteEvent(String eventId) async {
    return await deleteDocument(collection: 'events', id: eventId);
  }

  Future<bool> syncEventRegistration(Map<String, dynamic> data) async {
    return await syncDocument(collection: 'event_registrations', data: data);
  }

  Future<bool> deleteEventRegistration(String registrationId) async {
    return await deleteDocument(collection: 'event_registrations', id: registrationId);
  }

  Future<bool> syncNotification(NotificationModel notification) async {
    final doc = notification.toMap()..['id'] = notification.id;
    return await syncDocument(collection: 'notifications', data: doc);
  }

  Future<bool> syncNotificationMap(Map<String, dynamic> notifData) async {
    return await syncDocument(collection: 'notifications', data: notifData);
  }

  Future<bool> syncNotificationBatch(List<Map<String, dynamic>> notifications) async {
    return await syncBatch(collection: 'notifications', documents: notifications);
  }

  Future<bool> syncCommunityAlert(Map<String, dynamic> alertData) async {
    return await syncDocument(collection: 'community_alerts', data: alertData);
  }

  Future<bool> syncLostFoundItem(LostFoundModel item) async {
    final doc = item.toMap()..['id'] = item.id;
    return await syncDocument(collection: 'lost_found', data: doc);
  }

  Future<bool> syncLostFoundClaim(Map<String, dynamic> claimData) async {
    return await syncDocument(collection: 'lost_found_claims', data: claimData);
  }

  Future<bool> syncConnectionRequest(ConnectionRequestModel request) async {
    final doc = request.toMap()..['id'] = request.id;
    return await syncDocument(collection: 'connection_requests', data: doc);
  }

  Future<bool> syncConnection(ConnectionModel connection) async {
    final doc = connection.toMap()..['id'] = connection.id;
    return await syncDocument(collection: 'connections', data: doc);
  }

  Future<bool> deleteConnection(String connectionId) async {
    return await deleteDocument(collection: 'connections', id: connectionId);
  }

  Future<bool> syncReport(Map<String, dynamic> reportData) async {
    return await syncDocument(collection: 'reports', data: reportData);
  }

  Future<bool> syncAnnouncement(AnnouncementModel announcement) async {
    final doc = announcement.toMap()..['id'] = announcement.id;
    return await syncDocument(collection: 'announcements', data: doc);
  }

  Future<bool> syncAnnouncementMap(Map<String, dynamic> data) async {
    return await syncDocument(collection: 'announcements', data: data);
  }

  Future<bool> syncFlatVerificationRequest(Map<String, dynamic> requestData) async {
    return await syncDocument(collection: 'flat_verification_requests', data: requestData);
  }

  Future<bool> syncFlatAssignment(Map<String, dynamic> assignmentData) async {
    return await syncDocument(collection: 'flat_assignments', data: assignmentData);
  }

  Future<bool> deleteFlatAssignment(String flatNumber) async {
    return await deleteDocument(collection: 'flat_assignments', id: flatNumber);
  }

  Future<bool> syncJourney(Map<String, dynamic> journeyData) async {
    return await syncDocument(collection: 'journeys', data: journeyData);
  }

  Future<bool> syncJourneyLocation(String journeyId, Map<String, dynamic> locationData) async {
    final doc = Map<String, dynamic>.from(locationData)
      ..['journeyId'] = journeyId;
    return await syncDocument(collection: 'journey_locations', data: doc);
  }

  Future<bool> syncQuickPing(Map<String, dynamic> pingData) async {
    return await syncDocument(collection: 'quickPings', data: pingData);
  }

  Future<bool> syncContact(String userId, Map<String, dynamic> contactData) async {
    final contactId = contactData['id'] ?? '';
    final doc = Map<String, dynamic>.from(contactData)
      ..['id'] = '${userId}_$contactId'
      ..['userId'] = userId
      ..['contactId'] = contactId;
    return await syncDocument(collection: 'contacts', data: doc);
  }

  Future<bool> deleteContact(String userId, String contactId) async {
    final docId = '${userId}_$contactId';
    return await deleteDocument(collection: 'contacts', id: docId);
  }

  // ─── Initial Synchronization of Existing Firestore Data ───────────────────

  /// Safe initial synchronization of accessible Firestore documents to MongoDB
  Future<Map<String, dynamic>> syncAllFromFirestore() async {
    final db = FirebaseFirestore.instance;
    final summary = <String, dynamic>{};

    final collectionsToSync = [
      'users',
      'posts',
      'comments',
      'events',
      'event_registrations',
      'notifications',
      'community_alerts',
      'lost_found',
      'lost_found_claims',
      'connection_requests',
      'connections',
      'reports',
      'announcements',
      'flat_verification_requests',
      'flat_assignments',
      'journeys',
      'quickPings',
    ];

    for (final colName in collectionsToSync) {
      try {
        final snap = await db.collection(colName).limit(100).get();
        if (snap.docs.isNotEmpty) {
          final docs = snap.docs.map((d) => d.data()..['id'] = d.id).toList();
          final success = await syncBatch(collection: colName, documents: docs);
          summary[colName] = {
            'count': snap.docs.length,
            'synced': success,
          };
        } else {
          summary[colName] = {'count': 0, 'synced': true};
        }
      } catch (e) {
        debugPrint('[MongoSyncService] Initial sync skipped or failed for $colName: $e');
        summary[colName] = {'error': e.toString()};
      }
    }

    return summary;
  }
}
