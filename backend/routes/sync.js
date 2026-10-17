const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middleware/auth');

const User = require('../models/User');
const Post = require('../models/Post');
const Event = require('../models/Event');
const LostFound = require('../models/LostFound');
const Comment = require('../models/Comment');
const EventRegistration = require('../models/EventRegistration');
const Notification = require('../models/Notification');
const CommunityAlert = require('../models/CommunityAlert');
const LostFoundClaim = require('../models/LostFoundClaim');
const ConnectionRequest = require('../models/ConnectionRequest');
const Connection = require('../models/Connection');
const Report = require('../models/Report');
const Announcement = require('../models/Announcement');
const FlatVerificationRequest = require('../models/FlatVerificationRequest');
const FlatAssignment = require('../models/FlatAssignment');
const Journey = require('../models/Journey');
const JourneyLocation = require('../models/JourneyLocation');
const QuickPing = require('../models/QuickPing');
const Contact = require('../models/Contact');
const SyncQueue = require('../models/SyncQueue');

// Map of collection name to Mongoose model, including normalized aliases
const MODELS = {
  users: User,
  posts: Post,
  events: Event,
  lost_found: LostFound,
  comments: Comment,
  event_registrations: EventRegistration,
  notifications: Notification,
  community_alerts: CommunityAlert,
  lost_found_claims: LostFoundClaim,
  connection_requests: ConnectionRequest,
  connections: Connection,
  reports: Report,
  announcements: Announcement,
  flat_verification_requests: FlatVerificationRequest,
  flat_assignments: FlatAssignment,
  journeys: Journey,
  journey_locations: JourneyLocation,
  'journeys/locations': JourneyLocation,
  quickPings: QuickPing,
  quick_pings: QuickPing,
  contacts: Contact,
  'users/contacts': Contact,
};

const ADMIN_EMAIL = 'srimadhu6521@gmail.com';

/**
 * Robust date parser for numbers (ms), ISO strings, and Firestore Timestamp objects ({_seconds, _nanoseconds})
 */
function parseDate(val) {
  if (!val) return null;
  if (val instanceof Date) return val;
  if (typeof val === 'number') return new Date(val);
  if (typeof val === 'object') {
    const secs = val._seconds !== undefined ? val._seconds : val.seconds;
    if (typeof secs === 'number') {
      return new Date(secs * 1000);
    }
  }
  if (typeof val === 'string') {
    const parsed = Date.parse(val);
    if (!isNaN(parsed) && (val.includes('T') || val.includes('-'))) {
      return new Date(parsed);
    }
  }
  return null;
}

/**
 * Verifies if the requester has permission to modify the specific document
 */
function isAuthorizedForDoc(collectionName, doc, user) {
  if (!user) return false;
  if (user.email === ADMIN_EMAIL) return true;

  const uid = user.uid;

  switch (collectionName) {
    case 'users':
      return (doc.id || doc._id) === uid;
    case 'posts':
      // Allow post author or like/comment interactions
      return !doc.userId || doc.userId === uid || (Array.isArray(doc.likedBy) && doc.likedBy.includes(uid));
    case 'comments':
      return doc.authorId === uid;
    case 'events':
      return doc.createdBy === uid || (Array.isArray(doc.participants) && doc.participants.includes(uid));
    case 'event_registrations':
      return doc.userId === uid;
    case 'notifications':
      // User can update their own notifs, or create notifications sent to others in community alert / claims
      return doc.userId === uid || doc.senderId === uid || doc.claimantId === uid;
    case 'community_alerts':
      return doc.senderId === uid;
    case 'lost_found':
      return !doc.postedById || doc.postedById === uid;
    case 'lost_found_claims':
      return doc.claimantId === uid || doc.itemOwnerId === uid;
    case 'connection_requests':
      return doc.senderId === uid || doc.receiverId === uid;
    case 'connections':
      return doc.user1Id === uid || doc.user2Id === uid;
    case 'reports':
      return doc.userId === uid;
    case 'announcements':
      return false; // Admin only
    case 'flat_verification_requests':
      return doc.userId === uid;
    case 'flat_assignments':
      return false; // Admin only
    case 'journeys':
      return doc.userId === uid;
    case 'journey_locations':
    case 'journeys/locations':
      return true; // Authenticated user
    case 'quickPings':
    case 'quick_pings':
      return doc.userId === uid;
    case 'contacts':
    case 'users/contacts':
      return doc.userId === uid;
    default:
      return true;
  }
}

/**
 * Sanitizes and converts Firestore fields to MongoDB schema format
 */
function sanitizeDoc(collectionName, rawDoc) {
  const doc = { ...rawDoc };
  const docId = doc.id || doc._id;
  delete doc.id;
  doc._id = docId;
  doc._syncedAt = new Date();

  // Normalize date fields
  const dateKeys = [
    'createdAt',
    'updatedAt',
    'registeredAt',
    'requestedAt',
    'verifiedAt',
    'startTime',
    'endTime',
    'timestamp',
    'expiresAt',
    'addedAt',
    'flatVerificationRequestedAt',
  ];

  for (const key of dateKeys) {
    if (doc[key] !== undefined) {
      const parsed = parseDate(doc[key]);
      if (parsed) doc[key] = parsed;
    }
  }

  // Handle Event date (Timestamp) vs LostFound date (String)
  if (collectionName === 'events' && doc.date !== undefined) {
    const parsed = parseDate(doc.date);
    if (parsed) doc.date = parsed;
  }

  // Handle nested location timestamps
  if (doc.lastKnownLocation && doc.lastKnownLocation.timestamp) {
    const parsed = parseDate(doc.lastKnownLocation.timestamp);
    if (parsed) doc.lastKnownLocation.timestamp = parsed;
  }
  if (doc.location && typeof doc.location === 'object' && doc.location.timestamp) {
    const parsed = parseDate(doc.location.timestamp);
    if (parsed) doc.location.timestamp = parsed;
  }

  // Handle legacy field mappings
  if (collectionName === 'events') {
    if (doc.place && !doc.location) doc.location = doc.place;
    if (doc.location && !doc.place) doc.place = doc.location;
  }
  if (collectionName === 'lost_found') {
    if (doc.postedBy && !doc.postedByName) doc.postedByName = doc.postedBy;
    if (doc.postedByName && !doc.postedBy) doc.postedBy = doc.postedByName;
  }

  return { docId, payload: doc };
}

// POST /api/sync/batch - Idempotent batch sync endpoint for all supported collections
router.post('/batch', verifyFirebaseToken, async (req, res) => {
  const { collection: collectionName, documents } = req.body;

  if (!collectionName || !Array.isArray(documents)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid request: "collection" name and "documents" array are required',
    });
  }

  const Model = MODELS[collectionName];
  if (!Model) {
    return res.status(400).json({
      success: false,
      error: `Unsupported collection for sync: ${collectionName}. Supported: ${Object.keys(MODELS).join(', ')}`,
    });
  }

  const results = {
    total: documents.length,
    upserted: 0,
    failed: 0,
    errors: [],
  };

  for (const rawDoc of documents) {
    const { docId, payload } = sanitizeDoc(collectionName, rawDoc);
    if (!docId) {
      results.failed++;
      results.errors.push({ error: 'Document missing ID', item: rawDoc });
      continue;
    }

    // Check authorization
    if (!isAuthorizedForDoc(collectionName, rawDoc, req.user)) {
      results.failed++;
      results.errors.push({ id: docId, error: 'Forbidden: You do not have permission to sync this record' });
      continue;
    }

    try {
      await Model.findByIdAndUpdate(
        docId,
        { $set: payload },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
      results.upserted++;
    } catch (err) {
      results.failed++;
      results.errors.push({ id: docId, error: err.message });

      // Save to SyncQueue for resilience and logging
      await SyncQueue.create({
        collectionName,
        documentId: docId,
        payload: rawDoc,
        lastError: err.message,
        status: 'failed',
      }).catch(() => {});
    }
  }

  res.json({
    success: results.failed === 0,
    message: `Synchronized ${results.upserted}/${results.total} documents into ${collectionName}`,
    results,
  });
});

// DELETE /api/sync/:collection/:id - Delete a specific document safely
router.delete('/:collection/:id', verifyFirebaseToken, async (req, res) => {
  const { collection: collectionName, id: docId } = req.params;

  const Model = MODELS[collectionName];
  if (!Model) {
    return res.status(400).json({
      success: false,
      error: `Unsupported collection for delete: ${collectionName}`,
    });
  }

  try {
    const existing = await Model.findById(docId);
    if (!existing) {
      return res.json({ success: true, message: 'Document does not exist or already deleted' });
    }

    if (!isAuthorizedForDoc(collectionName, existing.toObject(), req.user)) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: You do not have permission to delete this record',
      });
    }

    await Model.findByIdAndDelete(docId);
    res.json({ success: true, message: `Deleted ${docId} from ${collectionName}` });
  } catch (error) {
    console.error(`[Delete Sync Error] ${collectionName}/${docId}:`, error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/sync/delete - Alternative POST endpoint for deletion
router.post('/delete', verifyFirebaseToken, async (req, res) => {
  const { collection: collectionName, id: docId } = req.body;

  if (!collectionName || !docId) {
    return res.status(400).json({ success: false, error: 'collection and id are required' });
  }

  const Model = MODELS[collectionName];
  if (!Model) {
    return res.status(400).json({ success: false, error: `Unsupported collection: ${collectionName}` });
  }

  try {
    const existing = await Model.findById(docId);
    if (!existing) {
      return res.json({ success: true, message: 'Document already deleted or not found' });
    }

    if (!isAuthorizedForDoc(collectionName, existing.toObject(), req.user)) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: You do not have permission to delete this record',
      });
    }

    await Model.findByIdAndDelete(docId);
    res.json({ success: true, message: `Deleted ${docId} from ${collectionName}` });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/sync/initial - Batch initial synchronization of multiple collections
router.post('/initial', verifyFirebaseToken, async (req, res) => {
  const { collections } = req.body;
  if (!collections || typeof collections !== 'object') {
    return res.status(400).json({ success: false, error: 'Expected "collections" object map' });
  }

  const summary = {};
  for (const [colName, docs] of Object.entries(collections)) {
    const Model = MODELS[colName];
    if (!Model || !Array.isArray(docs)) continue;

    let upserted = 0;
    let failed = 0;

    for (const rawDoc of docs) {
      const { docId, payload } = sanitizeDoc(colName, rawDoc);
      if (!docId) {
        failed++;
        continue;
      }

      if (!isAuthorizedForDoc(colName, rawDoc, req.user)) {
        failed++;
        continue;
      }

      try {
        await Model.findByIdAndUpdate(
          docId,
          { $set: payload },
          { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        upserted++;
      } catch (err) {
        failed++;
      }
    }

    summary[colName] = { total: docs.length, upserted, failed };
  }

  res.json({ success: true, summary, timestamp: new Date() });
});

// GET /api/sync/stats - Get MongoDB collection counts & sync status
router.get('/stats', verifyFirebaseToken, async (req, res) => {
  try {
    const stats = {};
    const seenModels = new Set();
    for (const [name, Model] of Object.entries(MODELS)) {
      if (seenModels.has(Model.modelName)) continue;
      seenModels.add(Model.modelName);
      stats[name] = await Model.countDocuments();
    }
    const failedQueue = await SyncQueue.countDocuments({ status: 'failed' });
    stats.failedInQueue = failedQueue;

    res.json({ success: true, stats, timestamp: new Date() });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
