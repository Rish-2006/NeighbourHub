const mongoose = require('mongoose');

const SyncQueueSchema = new mongoose.Schema(
  {
    collectionName: { type: String, required: true },
    documentId: { type: String, required: true },
    payload: { type: mongoose.Schema.Types.Mixed, required: true },
    retryCount: { type: Number, default: 0 },
    lastError: { type: String, default: null },
    status: { type: String, enum: ['pending', 'failed', 'completed'], default: 'pending' },
    createdAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
  }
);

SyncQueueSchema.index({ collectionName: 1, documentId: 1 });

module.exports = mongoose.model('SyncQueue', SyncQueueSchema, 'sync_queue');
