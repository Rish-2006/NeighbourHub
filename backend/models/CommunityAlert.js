const mongoose = require('mongoose');

const CommunityAlertSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore alert ID
    senderId: { type: String, required: true, index: true },
    senderName: { type: String, default: '' },
    senderApartment: { type: String, default: '' },
    type: { type: String, default: 'emergency' },
    message: { type: String, default: '' },
    status: { type: String, default: 'active' },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('CommunityAlert', CommunityAlertSchema, 'community_alerts');
