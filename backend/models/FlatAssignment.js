const mongoose = require('mongoose');

const FlatAssignmentSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // The flat number string itself (e.g., 'A101')
    userId: { type: String, required: true, index: true },
    userName: { type: String, default: '' },
    userEmail: { type: String, default: '' },
    verifiedAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('FlatAssignment', FlatAssignmentSchema, 'flat_assignments');
