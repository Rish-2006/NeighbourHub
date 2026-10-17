const mongoose = require('mongoose');

const ConnectionRequestSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Deterministic: ${senderId}_${receiverId}
    senderId: { type: String, required: true, index: true },
    senderName: { type: String, default: '' },
    receiverId: { type: String, required: true, index: true },
    receiverName: { type: String, default: '' },
    status: { type: String, default: 'pending' }, // 'pending', 'accepted', 'rejected'
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('ConnectionRequest', ConnectionRequestSchema, 'connection_requests');
