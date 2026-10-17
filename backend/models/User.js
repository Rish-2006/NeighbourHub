const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Stable Firestore UID
    name: { type: String, default: '', trim: true },
    email: { type: String, default: '', lowercase: true, trim: true },
    photoUrl: { type: String, default: '' },
    neighbourhood: { type: String, default: '' },
    apartment: { type: String, default: '' },
    bio: { type: String, default: '' },
    flatNumber: { type: String, default: '' },
    flatVerificationStatus: { type: String, default: 'Pending' },
    flatVerificationRequestedAt: { type: Date },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('User', UserSchema, 'users');
