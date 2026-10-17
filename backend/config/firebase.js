// backend/config/firebase.js
//
// Initialises Firebase Admin SDK (v12+ modular API).
// The legacy `admin.auth()` style no longer works in v12; use
// `getAuth()` from 'firebase-admin/auth' instead.

const { initializeApp, getApps, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const fs = require('fs');
const path = require('path');

let _app = null;

function initFirebase() {
  // Return existing app if already initialised
  const apps = getApps();
  if (apps.length > 0) {
    _app = apps[0];
    return _app;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  const projectId = process.env.FIREBASE_PROJECT_ID || 'neighbourhub-c0dfc';

  // ── Option A: Full service-account key file (preferred for production) ───
  if (serviceAccountPath) {
    const resolvedPath = path.resolve(process.cwd(), serviceAccountPath);
    if (fs.existsSync(resolvedPath)) {
      try {
        const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
        _app = initializeApp({
          credential: cert(serviceAccount),
          projectId: serviceAccount.project_id || projectId,
        });
        console.log('[Firebase] Initialised with Service Account Key file.');
        return _app;
      } catch (err) {
        console.error('[Firebase] Error reading service account file:', err.message);
      }
    } else {
      console.warn(`[Firebase] Service account file not found at: ${resolvedPath}`);
    }
  }

  // ── Option B: Project-ID only (uses Google public keys for token verification) ─
  try {
    _app = initializeApp({ projectId });
    console.log(`[Firebase] Initialised with Project ID (${projectId}) for token verification.`);
  } catch (err) {
    console.error('[Firebase] Initialisation error:', err.message);
  }

  return _app;
}

/**
 * Returns the Firebase Auth instance.
 * Must be called AFTER initFirebase().
 */
function getFirebaseAuth() {
  return getAuth(_app);
}

module.exports = { initFirebase, getFirebaseAuth };
