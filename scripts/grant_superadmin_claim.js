'use strict';

// Run only from a trusted machine with Application Default Credentials.
// Example:
//   GOOGLE_APPLICATION_CREDENTIALS=/secure/path/service-account.json \
//   FIREBASE_PROJECT_ID=myapp2-62246 TARGET_ADMIN_UID=<uid> node scripts/grant_superadmin_claim.js

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

async function main() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const uid = process.env.TARGET_ADMIN_UID;
  if (!projectId || !uid) {
    throw new Error('FIREBASE_PROJECT_ID and TARGET_ADMIN_UID are required.');
  }

  initializeApp({ projectId });
  const auth = getAuth();
  const user = await auth.getUser(uid);
  const existing = user.customClaims || {};
  await auth.setCustomUserClaims(uid, { ...existing, superadmin: true });
  await getFirestore().collection('admins').doc(uid).set({
    uid,
    role: 'superadmin',
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  process.stdout.write(`Granted superadmin claim and admin membership to ${uid}. Re-authenticate that account.\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.message || String(error)}\n`);
  process.exitCode = 1;
});
