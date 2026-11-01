const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");

initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 20 });

const db = getFirestore();
const MAX_MONEY = BigInt("9".repeat(1000));
const MAX_OPERATION = 999999999999999n;

function requireVerifiedUser(request) {
  if (!request.auth || request.auth.token.email_verified !== true) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول وتأكيد البريد الإلكتروني أولاً.");
  }
  return request.auth.uid;
}

function parseAmount(value) {
  if (typeof value !== "string" || !/^[1-9][0-9]{0,14}$/.test(value)) {
    throw new HttpsError("invalid-argument", "المبلغ غير صحيح.");
  }
  const amount = BigInt(value);
  if (amount <= 0n || amount > MAX_OPERATION) {
    throw new HttpsError("resource-exhausted", "المبلغ يتجاوز الحد المسموح للعملية الواحدة.");
  }
  return amount;
}

function parseBalance(value, fieldName) {
  const raw = value === undefined || value === null ? "0" : String(value);
  if (!/^[0-9]{1,1000}$/.test(raw)) {
    throw new HttpsError("failed-precondition", `تعذر قراءة ${fieldName} في حساب اللاعب.`);
  }
  return BigInt(raw);
}

function cleanHistory(value) {
  return Array.isArray(value) ? value.filter((entry) => entry && typeof entry === "object").slice(0, 59) : [];
}

function addHistory(current, title, detail, delta, at) {
  return [{ title, detail, money: delta, gold: 0, at: new Date(at).toISOString() }, ...cleanHistory(current)].slice(0, 60);
}

function playerName(data) {
  const name = typeof data?.name === "string" ? data.name.trim() : "";
  return name.length > 0 ? name.slice(0, 24) : "مزارع";
}

function balanceProjection(uid, name, money, updated) {
  return { uid, name: name.slice(0, 24), money: money.toString(), updated };
}

exports.moveBankMoney = onCall(async (request) => {
  const uid = requireVerifiedUser(request);
  const amount = parseAmount(request.data?.amount);
  const direction = request.data?.direction;
  if (direction !== "deposit" && direction !== "withdraw") {
    throw new HttpsError("invalid-argument", "نوع عملية البنك غير صحيح.");
  }

  const userRef = db.collection("users").doc(uid);
  const balanceRef = db.collection("friendBalances").doc(uid);
  let response;

  await db.runTransaction(async (transaction) => {
    const userSnapshot = await transaction.get(userRef);
    if (!userSnapshot.exists) throw new HttpsError("not-found", "لم يتم العثور على حسابك في قاعدة البيانات.");

    const account = userSnapshot.data();
    const cash = parseBalance(account.money, "رصيد المحفظة");
    const bank = parseBalance(account.bankMoney, "رصيد البنك");
    let nextCash;
    let nextBank;
    let historyTitle;
    let historyDetail;
    let historyDelta;

    if (direction === "deposit") {
      if (cash < amount) throw new HttpsError("failed-precondition", "رصيد المحفظة لا يكفي لهذا الإيداع.");
      nextCash = cash - amount;
      nextBank = bank + amount;
      historyTitle = "إيداع في البنك";
      historyDetail = `إيداع ${amount.toString()} د.ع`;
      historyDelta = -Number(amount);
    } else {
      if (bank < amount) throw new HttpsError("failed-precondition", "رصيد البنك لا يكفي لهذا السحب.");
      nextCash = cash + amount;
      nextBank = bank - amount;
      historyTitle = "سحب من البنك";
      historyDetail = `سحب ${amount.toString()} د.ع`;
      historyDelta = Number(amount);
    }

    if (nextCash > MAX_MONEY || nextBank > MAX_MONEY) {
      throw new HttpsError("resource-exhausted", "وصل أحد الرصيدين إلى الحد الأقصى المسموح.");
    }

    const updated = Date.now();
    const history = addHistory(account.transactions, historyTitle, historyDetail, historyDelta, updated);
    transaction.update(userRef, {
      money: nextCash.toString(),
      bankMoney: nextBank.toString(),
      transactions: history,
      updated,
    });
    transaction.set(balanceRef, balanceProjection(uid, playerName(account), nextCash, updated), { merge: true });

    response = {
      money: nextCash.toString(),
      bankMoney: nextBank.toString(),
      transactions: history,
    };
  });

  return response;
});

exports.transferMoney = onCall(async (request) => {
  const senderUid = requireVerifiedUser(request);
  const receiverUid = typeof request.data?.toUid === "string" ? request.data.toUid.trim() : "";
  const amount = parseAmount(request.data?.amount);

  if (!receiverUid || receiverUid.length > 128) {
    throw new HttpsError("invalid-argument", "معرّف اللاعب المستلم غير صحيح.");
  }
  if (receiverUid === senderUid) {
    throw new HttpsError("invalid-argument", "لا يمكنك تحويل الأموال إلى حسابك نفسه.");
  }

  const senderRef = db.collection("users").doc(senderUid);
  const receiverRef = db.collection("users").doc(receiverUid);
  const senderProfileRef = db.collection("publicProfiles").doc(senderUid);
  const receiverProfileRef = db.collection("publicProfiles").doc(receiverUid);
  const senderBalanceRef = db.collection("friendBalances").doc(senderUid);
  const receiverBalanceRef = db.collection("friendBalances").doc(receiverUid);
  let response;

  await db.runTransaction(async (transaction) => {
    const [senderSnapshot, receiverSnapshot, senderProfileSnapshot, receiverProfileSnapshot] = await Promise.all([
      transaction.get(senderRef),
      transaction.get(receiverRef),
      transaction.get(senderProfileRef),
      transaction.get(receiverProfileRef),
    ]);

    if (!senderSnapshot.exists) throw new HttpsError("not-found", "لم يتم العثور على حسابك.");
    if (!receiverSnapshot.exists || !receiverProfileSnapshot.exists) {
      throw new HttpsError("not-found", "لم يتم العثور على حساب اللاعب المستلم.");
    }

    const sender = senderSnapshot.data();
    const receiver = receiverSnapshot.data();
    const senderCash = parseBalance(sender.money, "رصيدك");
    const receiverCash = parseBalance(receiver.money, "رصيد المستلم");
    if (senderCash < amount) throw new HttpsError("failed-precondition", "رصيدك المتاح لا يكفي للتحويل.");
    if (receiverCash + amount > MAX_MONEY) {
      throw new HttpsError("resource-exhausted", "لا يمكن إضافة المبلغ؛ رصيد المستلم وصل إلى الحد الأعلى.");
    }

    const nextSenderCash = senderCash - amount;
    const nextReceiverCash = receiverCash + amount;
    const senderName = playerName(senderProfileSnapshot.exists ? senderProfileSnapshot.data() : sender);
    const receiverName = playerName(receiverProfileSnapshot.data());
    const updated = Date.now();
    const senderHistory = addHistory(sender.transactions, "تحويل أموال", `إلى ${receiverName}`, -Number(amount), updated);
    const receiverHistory = addHistory(receiver.transactions, "استلام تحويل", `من ${senderName}`, Number(amount), updated);

    transaction.update(senderRef, {
      money: nextSenderCash.toString(),
      transactions: senderHistory,
      updated,
    });
    transaction.update(receiverRef, {
      money: nextReceiverCash.toString(),
      transactions: receiverHistory,
      updated,
    });
    transaction.set(senderBalanceRef, balanceProjection(senderUid, senderName, nextSenderCash, updated), { merge: true });
    transaction.set(receiverBalanceRef, balanceProjection(receiverUid, receiverName, nextReceiverCash, updated), { merge: true });

    response = {
      money: nextSenderCash.toString(),
      bankMoney: parseBalance(sender.bankMoney, "رصيد البنك").toString(),
      transactions: senderHistory,
      receiverName,
    };
  });

  return response;
});


// Keep the friends-only cash-balance projection authoritative. Clients cannot
// write friendBalances directly; this trigger mirrors each committed game save.
exports.syncFriendBalance = onDocumentWritten("users/{uid}", async (event) => {
  const after = event.data?.after;
  if (!after || !after.exists) return;

  const uid = event.params.uid;
  const account = after.data();
  const money = parseBalance(account.money, "رصيد المحفظة");
  const name = playerName(account);
  const updated = typeof account.updated === "number" ? account.updated : Date.now();

  await db.collection("friendBalances").doc(uid).set(
    balanceProjection(uid, name, money, updated),
    { merge: true },
  );
});
