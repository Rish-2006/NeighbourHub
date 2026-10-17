const mongoose = require('mongoose');

const JourneyLocationSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore location doc ID (UUID)
    journeyId: { type: String, required: true, index: true },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    altitude: { type: Number },
    speed: { type: Number },
    timestamp: { type: Date, default: Date.now },
    batteryLevel: { type: Number },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('JourneyLocation', JourneyLocationSchema, 'journey_locations');
