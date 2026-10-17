const express = require('express');
const router = express.Router();
const verifyFirebaseToken = require('../middleware/auth');
const User = require('../models/User');

// GET /api/users - Get all users
router.get('/', verifyFirebaseToken, async (req, res) => {
  try {
    const users = await User.find({}).sort({ createdAt: -1 });
    res.json({ success: true, count: users.length, data: users });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/users/:id - Get specific user
router.get('/:id', verifyFirebaseToken, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found in MongoDB' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/users/sync - Safe idempotent sync for user profile
router.post('/sync', verifyFirebaseToken, async (req, res) => {
  try {
    const { id, name, email, photoUrl, neighbourhood, apartment, bio, createdAt } = req.body;

    // Security: Authenticated user can only sync their own profile (or admin)
    const requesterUid = req.user.uid;
    const targetId = id || requesterUid;

    if (requesterUid !== targetId && req.user.email !== 'srimadhu6521@gmail.com') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: You can only synchronize your own user record',
      });
    }

    const updateDoc = {
      _id: targetId,
      name: name !== undefined ? name : '',
      email: email !== undefined ? email : (req.user.email || ''),
      photoUrl: photoUrl !== undefined ? photoUrl : '',
      neighbourhood: neighbourhood !== undefined ? neighbourhood : '',
      apartment: apartment !== undefined ? apartment : '',
      bio: bio !== undefined ? bio : '',
      updatedAt: new Date(),
      _syncedAt: new Date(),
    };

    if (createdAt) {
      updateDoc.createdAt = new Date(createdAt);
    }

    // Upsert into MongoDB
    const syncedUser = await User.findByIdAndUpdate(
      targetId,
      { $set: updateDoc },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    res.json({
      success: true,
      message: 'User synchronized successfully to MongoDB',
      data: syncedUser,
    });
  } catch (error) {
    console.error('User sync error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
