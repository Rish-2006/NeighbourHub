const mongoose = require('mongoose');

const EventSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    date: { type: Date, required: true },
    startTime: { type: String, default: '' },
    endTime: { type: String, default: '' },
    place: { type: String, default: '' },
    location: { type: String, default: '' },
    additionalDetails: { type: String, default: '' },
    emoji: { type: String, default: '' },
    category: { type: String, default: 'General' },
    createdBy: { type: String, default: '' },
    createdByName: { type: String, default: '' },
    participants: { type: [String], default: [] },
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Event', EventSchema, 'events');
