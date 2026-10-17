const mongoose = require('mongoose');

const ConnectionSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Deterministic: ${sortedId1}_${sortedId2}
    user1Id: { type: String, required: true, index: true },
    user2Id: { type: String, required: true, index: true },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Connection', ConnectionSchema, 'connections');
