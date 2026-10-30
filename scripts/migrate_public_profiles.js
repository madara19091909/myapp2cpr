'use strict';

// Remove legacy farmPlots from publicProfiles. Run once from a trusted machine
// with firebase-admin and Application Default Credentials configured.
//   FIREBASE_PROJECT_ID=myapp2-62246 node scripts/migrate_public_profiles.js

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldPath, FieldValue } = require('firebase-admin/firestore');

async function main() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!projectId) throw new Error('FIREBASE_PROJECT_ID is required.');
  initializeApp({ projectId });
  const db = getFirestore();
  const collection = db.collection('publicProfiles');
  let cursor = null;
  let scanned = 0;
  let changed = 0;

  while (true) {
    let query = collection.orderBy(FieldPath.documentId()).limit(400);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;
    const batch = db.batch();
    let pageChanges = 0;
    for (const doc of page.docs) {
      scanned += 1;
      const data = doc.data();
      const patch = {};
      // Remove legacy private farm data and unverified economy fields from
      // existing public documents before deploying the new client/rules.
      for (const field of ['farmPlots', 'money', 'level']) {
        if (Object.prototype.hasOwnProperty.call(data, field)) {
          patch[field] = FieldValue.delete();
        }
      }
      if (Object.keys(patch).length > 0) {
        batch.update(doc.ref, patch);
        pageChanges += 1;
      }
    }
    if (pageChanges) {
      await batch.commit();
      changed += pageChanges;
    }
    cursor = page.docs[page.docs.length - 1];
    if (page.size < 400) break;
  }

  process.stdout.write(`Scanned ${scanned} public profiles; cleaned legacy farm/economy fields from ${changed}.\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.message || String(error)}\n`);
  process.exitCode = 1;
});
