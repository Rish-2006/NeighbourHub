const mongoose = require('mongoose');

const EventRegistrationSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Deterministic: ${eventId}_${userId}
    eventId: { type: String, required: true, index: true },
    userId: { type: String, required: true, index: true },
    userName: { type: String, default: '' },
    userEmail: { type: String, default: '' },
    flatNumber: { type: String, default: '' },
    registeredAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('EventRegistration', EventRegistrationSchema, 'event_registrations');
