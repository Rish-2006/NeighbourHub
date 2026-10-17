const mongoose = require('mongoose');

const QuickPingSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore pingId (UUID)
    userId: { type: String, required: true, index: true },
    location: {
      latitude: { type: Number },
      longitude: { type: Number },
      altitude: { type: Number },
      speed: { type: Number },
      timestamp: { type: Date },
      batteryLevel: { type: Number },
    },
    contactIds: { type: [String], default: [] },
    timestamp: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('QuickPing', QuickPingSchema, 'quick_pings');
