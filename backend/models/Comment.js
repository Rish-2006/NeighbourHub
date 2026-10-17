const mongoose = require('mongoose');

const CommentSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore comment ID (UUID)
    postId: { type: String, required: true, index: true },
    authorId: { type: String, required: true, index: true },
    authorName: { type: String, default: '' },
    authorPhoto: { type: String, default: '' },
    text: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Comment', CommentSchema, 'comments');
