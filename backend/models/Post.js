const mongoose = require('mongoose');

const PostSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Stable Firestore Post ID
    userId: { type: String, required: true, index: true },
    userName: { type: String, default: '' },
    userPhoto: { type: String, default: '' },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    type: { type: String, default: 'general' },
    imageUrl: { type: String, default: '' },
    likesCount: { type: Number, default: 0 },
    likedBy: { type: [String], default: [] },
    commentsCount: { type: Number, default: 0 },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Post', PostSchema, 'posts');
