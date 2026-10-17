const mongoose = require('mongoose');

const AnnouncementSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore announcement ID
    title: { type: String, required: true },
    description: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    createdBy: { type: String, default: '' },
    createdByEmail: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Announcement', AnnouncementSchema, 'announcements');
