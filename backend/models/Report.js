const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, // Firestore report ID
    userId: { type: String, required: true, index: true },
    userName: { type: String, default: '' },
    userEmail: { type: String, default: '' },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    category: { type: String, default: 'Other' },
    imageUrl: { type: String, default: '' },
    status: { type: String, default: 'Pending' }, // 'Pending', 'In Progress', 'Resolved'
    createdAt: { type: Date, default: Date.now },
    _syncedAt: { type: Date, default: Date.now },
  },
  {
    _id: false,
    timestamps: true,
  }
);

module.exports = mongoose.model('Report', ReportSchema, 'reports');
