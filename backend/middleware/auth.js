// backend/middleware/auth.js
//
// Express middleware that verifies Firebase ID tokens sent in the
// `Authorization: Bearer <token>` header.
//
// Uses the modular firebase-admin/auth API (v12+).

const { getFirebaseAuth } = require('../config/firebase');

async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Missing or invalid Authorization header. Expected Bearer <token>',
    });
  }

  const idToken = authHeader.split('Bearer ')[1].trim();

  if (!idToken) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Empty token provided',
    });
  }

  try {
    const auth = getFirebaseAuth();
    const decodedToken = await auth.verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('[Auth Middleware] Token verification failed:', error.message);
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Invalid or expired Firebase ID token',
      details: error.code || error.message,
    });
  }
}

module.exports = verifyFirebaseToken;
