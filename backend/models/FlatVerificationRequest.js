const mongoose = require('mongoose');

const FlatVerificationRequestSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore request ID
    userId: { type: String, required: true, index: true },
    userName: { type: String, default: '' },
    userEmail: { type: String, default: '' },
    flatNumber: { type: String, required: true },
    status: { type: String, default: 'Pending' }, // 'Pending', 'Approved', 'Rejected', 'Cancelled'
    requestedAt: { type: Date, default: Date.now },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model(
  'FlatVerificationRequest',
  FlatVerificationRequestSchema,
  'flat_verification_requests'
);
