'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const { defaults, applyAction, importLegacyState } = require('./game_engine');

initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 30, memory: '256MiB', timeoutSeconds: 20 });
const db = getFirestore();

function assertVerified(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول.');
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError('permission-denied', 'يجب تأكيد البريد الإلكتروني أولاً.');
  }
}
function publicData(uid, state, now) {
  return { uid, name: String(state.name || 'المزارع').slice(0, 24), updated: now.getTime() };
}
function farmData(uid, state, now) {
  return {
    uid,
    name: String(state.name || 'المزارع').slice(0, 24),
    plots: (state.plots || []).map(p => ({
      cropId: p.crop || null, plantedAt: p.at || null,
      growSeconds: Number.isSafeInteger(p.sec) ? p.sec : 0, watered: p.watered === true,
    })),
    updated: now.getTime(),
  };
}
function writeDerived(tx, uid, state, now) {
  tx.set(db.collection('publicProfiles').doc(uid), publicData(uid, state, now));
  tx.set(db.collection('farmSnapshots').doc(uid), farmData(uid, state, now));
}
function mapError(error) {
  if (error instanceof HttpsError) return error;
  if (error && error.code === 'failed-precondition') return new HttpsError('failed-precondition', error.message);
  if (error && error.code === 'invalid-argument') return new HttpsError('invalid-argument', error.message);
  return new HttpsError('internal', 'تعذرت معالجة العملية بأمان. حاول مرة أخرى.');
}

exports.bootstrapGame = onCall({ enforceAppCheck: true }, async request => {
  assertVerified(request);
  const uid = request.auth.uid;
  const now = new Date();
  const stateRef = db.collection('gameStates').doc(uid);
  const legacyRef = db.collection('users').doc(uid);
  const bootstrapRateRef = db.collection('bootstrapLimits').doc(uid);
  try {
    return await db.runTransaction(async tx => {
      const current = await tx.get(stateRef);
      const rateSnap = await tx.get(bootstrapRateRef);
      // Firestore requires every transaction read to finish before its first write.
      // Read the legacy record up front when this is a first-time bootstrap.
      const old = current.exists ? null : await tx.get(legacyRef);
      const rate = rateSnap.exists ? rateSnap.data() : {};
      const windowStart = Number(rate.windowStart || 0);
      const inWindow = Number.isFinite(windowStart) && now.getTime() - windowStart >= 0 && now.getTime() - windowStart < 60000;
      const count = inWindow ? Number(rate.count || 0) : 0;
      if (!Number.isSafeInteger(count) || count >= 30) {
        throw new HttpsError('resource-exhausted', 'طلبات فتح اللعبة كثيرة. حاول بعد دقيقة.');
      }
      tx.set(bootstrapRateRef, { windowStart: inWindow ? windowStart : now.getTime(), count: count + 1, updatedAt: Timestamp.fromDate(now) });
      if (current.exists) {
        const outcome = applyAction(current.data(), 'refresh', {}, now);
        const state = outcome.state;
        tx.set(stateRef, state);
        writeDerived(tx, uid, state, now);
        return { state, result: outcome.result, serverTime: now.toISOString(), legacyUnverified: state.legacyUnverified === true };
      }
      // Preserve legacy progression for continuity, but explicitly mark it unverified:
      // old client-writable balances cannot be proven honest retrospectively.
      const imported = old && old.exists ? importLegacyState(old.data(), now) : defaults(
        typeof request.auth.token.name === 'string' ? request.auth.token.name.slice(0, 24) : 'المزارع', now,
      );
      const state = applyAction(imported, 'refresh', {}, now).state;
      state.updated = now.getTime();
      tx.create(stateRef, state);
      writeDerived(tx, uid, state, now);
      return { state, serverTime: now.toISOString(), legacyUnverified: state.legacyUnverified === true };
    });
  } catch (error) { throw mapError(error); }
});

exports.applyGameAction = onCall({ enforceAppCheck: true }, async request => {
  assertVerified(request);
  const uid = request.auth.uid;
  const body = request.data || {};
  const action = typeof body.action === 'string' ? body.action : '';
  const args = body.args && typeof body.args === 'object' ? body.args : {};
  const requestId = typeof body.requestId === 'string' ? body.requestId : '';
  if (!/^[A-Za-z0-9_-]{16,80}$/.test(requestId)) {
    throw new HttpsError('invalid-argument', 'معرّف العملية غير صالح.');
  }
  if (!action || action.length > 40) throw new HttpsError('invalid-argument', 'نوع العملية غير صالح.');

  const stateRef = db.collection('gameStates').doc(uid);
  const receiptRef = db.collection('gameActionReceipts').doc(uid).collection('items').doc(requestId);
  const rateRef = db.collection('gameActionLimits').doc(uid);
  const now = new Date();
  try {
    // Consume rate-limit budget before business validation. Otherwise callers
    // could flood the function with invalid actions that abort the transaction
    // before the counter is committed.
    await db.runTransaction(async tx => {
      const receipt = await tx.get(receiptRef);
      if (receipt.exists) return;
      const rateSnap = await tx.get(rateRef);
      const rate = rateSnap.exists ? rateSnap.data() : {};
      const windowStart = Number(rate.windowStart || 0);
      const inWindow = Number.isFinite(windowStart) && now.getTime() - windowStart >= 0 && now.getTime() - windowStart < 60000;
      const count = inWindow ? Number(rate.count || 0) : 0;
      if (!Number.isSafeInteger(count) || count >= 120) {
        throw new HttpsError('resource-exhausted', 'تم تجاوز عدد العمليات المسموح به مؤقتاً. حاول بعد دقيقة.');
      }
      tx.set(rateRef, { windowStart: inWindow ? windowStart : now.getTime(), count: count + 1, updatedAt: Timestamp.fromDate(now) });
    });

    return await db.runTransaction(async tx => {
      const receipt = await tx.get(receiptRef);
      const stateSnap = await tx.get(stateRef);
      if (receipt.exists) {
        if (!stateSnap.exists) throw new HttpsError('failed-precondition', 'حالة اللعبة غير موجودة.');
        const saved = receipt.data();
        return { state: stateSnap.data(), result: saved.result || { ok: true, data: {} }, serverTime: now.toISOString(), legacyUnverified: stateSnap.data().legacyUnverified === true };
      }
      if (!stateSnap.exists) throw new HttpsError('failed-precondition', 'يجب تهيئة حساب اللعبة أولاً. أعد فتح اللعبة.');
      const before = stateSnap.data();
      const outcome = applyAction(before, action, args, now);
      const state = outcome.state;
      tx.set(stateRef, state);
      writeDerived(tx, uid, state, now);
      const response = {
        state,
        result: outcome.result,
        serverTime: now.toISOString(),
        legacyUnverified: state.legacyUnverified === true,
      };
      tx.create(receiptRef, {
        result: outcome.result,
        createdAt: Timestamp.fromDate(now),
        expireAt: Timestamp.fromDate(new Date(now.getTime() + 30 * 86400000)),
      });
      return response;
    });
  } catch (error) { throw mapError(error); }
});


// Administrative operations are server-side, allow-listed, bounded and audited.
exports.adminUpdatePlayer = onCall({ enforceAppCheck: true }, async request => {
  assertVerified(request);
  const actorUid = request.auth.uid;
  const body = request.data || {};
  const targetUid = typeof body.targetUid === 'string' ? body.targetUid : '';
  const reason = typeof body.reason === 'string' ? body.reason.trim() : '';
  const patch = body.patch && typeof body.patch === 'object' && !Array.isArray(body.patch) ? body.patch : {};
  if (!targetUid || targetUid.length > 128 || reason.length < 5 || reason.length > 200) {
    throw new HttpsError('invalid-argument', 'معرّف اللاعب وسبب التعديل مطلوبان.');
  }
  const keys = Object.keys(patch);
  const allowed = new Set(['name', 'money', 'gold', 'level', 'xp', 'resetFarm', 'verifyLegacy']);
  if (keys.some(key => !allowed.has(key))) throw new HttpsError('invalid-argument', 'الحقول المطلوبة غير مسموحة.');
  if (patch.name !== undefined && (typeof patch.name !== 'string' || !patch.name.trim() || patch.name.trim().length > 24)) {
    throw new HttpsError('invalid-argument', 'اسم اللاعب غير صالح.');
  }
  const bounds = { money: [0, 2_000_000_000], gold: [0, 1_000_000], level: [1, 1_000_000], xp: [0, 1_000_000_000] };
  for (const [field, [min, max]] of Object.entries(bounds)) {
    if (patch[field] !== undefined && (!Number.isSafeInteger(patch[field]) || patch[field] < min || patch[field] > max)) {
      throw new HttpsError('invalid-argument', `قيمة ${field} خارج الحدود.`);
    }
  }
  if (patch.resetFarm !== undefined && patch.resetFarm !== true) throw new HttpsError('invalid-argument', 'قيمة resetFarm غير صالحة.');
  if (patch.verifyLegacy !== undefined && patch.verifyLegacy !== true) throw new HttpsError('invalid-argument', 'قيمة verifyLegacy غير صالحة.');

  const adminRef = db.collection('admins').doc(actorUid);
  const stateRef = db.collection('gameStates').doc(targetUid);
  const auditRef = db.collection('adminAuditLogs').doc();
  const now = new Date();
  try {
    return await db.runTransaction(async tx => {
      const adminSnap = await tx.get(adminRef);
      if (!adminSnap.exists) throw new HttpsError('permission-denied', 'صلاحيات الإدارة غير متاحة.');
      const stateSnap = await tx.get(stateRef);
      if (!stateSnap.exists) throw new HttpsError('not-found', 'لم تتم تهيئة حساب هذا اللاعب بعد.');
      const before = stateSnap.data();
      const state = { ...before };
      const changes = {};
      for (const field of ['name', 'money', 'gold', 'level', 'xp']) {
        if (patch[field] !== undefined && patch[field] !== state[field]) {
          changes[field] = { from: state[field] ?? null, to: patch[field] };
          state[field] = field === 'name' ? patch[field].trim().replace(/\s+/g, ' ') : patch[field];
        }
      }
      if (patch.resetFarm === true) {
        changes.resetFarm = true;
        state.seeds = {}; state.harvestedCrops = {}; state.animals = {}; state.products = {};
        state.activeCrafts = []; state.collect = {}; state.boostedCycles = {}; state.animalFeed = 0;
        state.plots = Array.from({ length: 9 }, () => ({ crop: null, at: null, sec: 0, watered: false }));
      }
      if (patch.verifyLegacy === true) {
        changes.verifyLegacy = true;
        state.legacyUnverified = false;
        state.legacyVerifiedAt = now.toISOString();
        state.legacyVerifiedBy = actorUid;
      }
      state.revision = Math.min(1_000_000_000, Number(state.revision || 0) + 1);
      state.updated = now.getTime();
      tx.set(stateRef, state);
      writeDerived(tx, targetUid, state, now);
      tx.create(auditRef, {
        actorUid, targetUid, reason, changes,
        before: Object.fromEntries(Object.keys(changes).filter(k => ['money','gold','level','xp','name'].includes(k)).map(k => [k, changes[k].from])),
        after: Object.fromEntries(Object.keys(changes).filter(k => ['money','gold','level','xp','name'].includes(k)).map(k => [k, changes[k].to])),
        createdAt: Timestamp.fromDate(now),
      });
      return { state, serverTime: now.toISOString(), legacyUnverified: state.legacyUnverified === true };
    });
  } catch (error) { throw mapError(error); }
});
