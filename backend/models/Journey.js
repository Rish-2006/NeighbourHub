const mongoose = require('mongoose');

const JourneySchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore journeyId (UUID)
    userId: { type: String, required: true, index: true },
    isActive: { type: Boolean, default: true },
    startTime: { type: Date, default: Date.now },
    endTime: { type: Date },
    destinationName: { type: String, default: '' },
    lastKnownLocation: {
      latitude: { type: Number },
      longitude: { type: Number },
      altitude: { type: Number },
      speed: { type: Number },
      timestamp: { type: Date },
      batteryLevel: { type: Number },
    },
    contactIds: { type: [String], default: [] },
    isPanicTriggered: { type: Boolean, default: false },
    isBatteryAlerted: { type: Boolean, default: false },
    isInactivityAlerted: { type: Boolean, default: false },
    expiresAt: { type: Date },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Journey', JourneySchema, 'journeys');
