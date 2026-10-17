const mongoose = require('mongoose');

const ContactSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Format: ${userId}_${contactId} or contactId
    userId: { type: String, required: true, index: true },
    contactId: { type: String, default: '' },
    name: { type: String, default: '' },
    phone: { type: String, default: '' },
    email: { type: String, default: '' },
    relationship: { type: String, default: '' },
    addedAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Contact', ContactSchema, 'contacts');
