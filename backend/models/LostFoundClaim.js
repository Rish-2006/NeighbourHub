const mongoose = require('mongoose');

const LostFoundClaimSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore claim ID
    itemId: { type: String, required: true, index: true },
    itemTitle: { type: String, default: '' },
    itemOwnerId: { type: String, required: true, index: true },
    claimantId: { type: String, required: true, index: true },
    claimantName: { type: String, default: '' },
    claimLocation: { type: String, default: '' },
    claimDescription: { type: String, default: '' },
    claimType: { type: String, default: 'claim' }, // 'claim' or 'found_tip'
    status: { type: String, default: 'pending' }, // 'pending', 'accepted', 'rejected'
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('LostFoundClaim', LostFoundClaimSchema, 'lost_found_claims');
