const mongoose = require('mongoose');

const LostFoundSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    category: { type: String, default: 'Other' },
    type: { type: String, default: 'Lost' }, // 'Lost' or 'Found'
    location: { type: String, default: '' },
    date: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    contactPhone: { type: String, default: '' },
    postedBy: { type: String, default: '' },
    postedById: { type: String, required: true },
    postedByName: { type: String, default: '' },
    postedByApartment: { type: String, default: '' },
    status: { type: String, default: 'Active' },
    isResolved: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('LostFound', LostFoundSchema, 'lost_found');
