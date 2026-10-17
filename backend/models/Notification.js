const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore notification ID
    userId: { type: String, required: true, index: true },
    title: { type: String, default: '' },
    message: { type: String, default: '' },
    type: { type: String, default: 'general' },
    isRead: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
    reportId: { type: String, default: '' },
    status: { type: String, default: '' },
    senderId: { type: String, default: '' },
    senderName: { type: String, default: '' },
    senderApartment: { type: String, default: '' },
    alertId: { type: String, default: '' },
    claimId: { type: String, default: '' },
    itemId: { type: String, default: '' },
    requestId: { type: String, default: '' },
    requestedFlat: { type: String, default: '' },
    requestingUserId: { type: String, default: '' },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Notification', NotificationSchema, 'notifications');
