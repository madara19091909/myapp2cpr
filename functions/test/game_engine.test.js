'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { defaults, applyAction, importLegacyState, sanitizeState } = require('../src/game_engine');

const now = new Date('2026-10-30T10:00:00.000Z');

function act(state, action, args = {}) {
  return applyAction(state, action, args, new Date(now));
}

test('a new account starts from bounded server defaults', () => {
  const state = defaults('مزارع', now);
  assert.equal(state.money, 18000);
  assert.equal(state.gold, 12);
  assert.equal(state.plots.length, 9);
});

test('client cannot choose prices or credit its own balance', () => {
  const state = defaults('مزارع', now);
  assert.throws(() => act(state, 'buySeed', { id: 'wheat', qty: 25 }), /رصيدك غير كافٍ/);
  assert.equal(state.money, 18000);
});

test('server limits seed quantity and accepts only catalog identifiers', () => {
  const state = defaults('مزارع', now);
  assert.throws(() => act(state, 'buySeed', { id: 'unknown', qty: 1 }), /غير موجود/);
  assert.throws(() => act(state, 'buySeed', { id: 'wheat', qty: 999 }), /رصيدك غير كافٍ|يتطلب|ممتلئ/);
});

test('planting time and growth duration come from server time and catalog', () => {
  const state = defaults('مزارع', now);
  state.seeds.wheat = 1;
  const result = act(state, 'plant', { id: 'wheat', index: 0, at: '2000-01-01', sec: 1 });
  assert.equal(result.state.plots[0].at, now.toISOString());
  assert.ok(result.state.plots[0].sec > 1);
  assert.equal(result.state.seeds.wheat, undefined);
});

test('daily reward cannot be claimed twice on the same Baghdad day', () => {
  const first = act(defaults('مزارع', now), 'claimDailyReward');
  assert.equal(first.state.dailyStreak, 1);
  assert.throws(() => act(first.state, 'claimDailyReward'), /بالفعل/);
});

test('client cannot harvest an unripe crop by spoofing local clock', () => {
  const state = defaults('مزارع', now);
  state.plots[0] = { crop: 'wheat', at: now.toISOString(), sec: 3600, watered: false };
  assert.throws(() => act(state, 'harvest', { index: 0, now: '2035-01-01T00:00:00Z' }), /لا توجد محاصيل ناضجة/);
});

test('buying a seed deducts exact server-side catalog cost', () => {
  const state = defaults('مزارع', now);
  state.money = 20000;
  const result = act(state, 'buySeed', { id: 'wheat', qty: 2 });
  assert.equal(result.state.money, 5000);
  assert.equal(result.state.seeds.wheat, 2);
});

test('selling crop inventory uses server-calculated tax and fee', () => {
  const state = defaults('مزارع', now);
  state.harvestedCrops.wheat = 2;
  const result = act(state, 'sellCrop', { id: 'wheat', qty: 1 });
  assert.equal(result.state.harvestedCrops.wheat, 1);
  assert.ok(result.result.data.tax >= 0);
  assert.ok(result.state.money > 18000);
});

test('legacy imports are clearly marked unverified', () => {
  const imported = importLegacyState({ name: 'قديم', money: 123456 }, now);
  assert.equal(imported.legacyUnverified, true);
  assert.equal(imported.money, 123456);
  assert.equal(imported.legacyImportedAt, now.toISOString());
  assert.equal(imported.lastActiveAt, now.toISOString());
  assert.equal(imported.lastDailyRewardDate, require('../src/game_engine').dateKey(now));
  assert.deepEqual(imported.activeCrafts, []);
});

test('legacy timestamps and queues cannot grant instant crops, animal income or craft products', () => {
  const old = defaults('قديم', new Date('2000-01-01T00:00:00.000Z'));
  old.plots[0] = { crop: 'wheat', at: '2000-01-01T00:00:00.000Z', sec: 1, watered: true };
  old.animals.chicken = 1; old.collect.chicken = '2000-01-01T00:00:00.000Z';
  old.activeCrafts = [{ id: 'bread', outputId: 'bread', outputName: 'خبز', qty: 20, readyAt: '2000-01-01T00:00:00.000Z' }];
  const imported = importLegacyState(old, now);
  assert.equal(imported.plots[0].at, now.toISOString());
  assert.ok(imported.plots[0].sec > 1);
  assert.equal(imported.collect.chicken, now.toISOString());
  assert.deepEqual(imported.activeCrafts, []);
  const normalized = sanitizeState({ ...defaults('x', now), activeCrafts: [{ id: 'bread', outputId: 'cake', qty: 20, readyAt: now.toISOString() }] }, now);
  assert.deepEqual(normalized.activeCrafts, []);
});

test('client cannot grant offline reward by forging an old last-active timestamp during import', () => {
  const imported = importLegacyState({ money: 1000, lastActiveAt: '2000-01-01T00:00:00.000Z' }, now);
  const refreshed = act(imported, 'refresh');
  assert.equal(refreshed.result.data?.offlineReward, undefined);
  assert.equal(refreshed.state.money, 1000);
});

test('unknown actions fail closed', () => {
  assert.throws(() => act(defaults('مزارع', now), 'setMoney', { money: 999999999 }), /غير معروفة/);
});

test('legacy accounts cannot run any economy or reward action until reviewed', () => {
  const imported = importLegacyState({ name: 'قديم', money: 900000, dailyStreak: 6, luckyStreak: 50 }, now);
  assert.equal(imported.dailyStreak, 0);
  assert.equal(imported.luckyStreak, 0);
  assert.throws(() => act(imported, 'claimDailyReward'), /قيد المراجعة|مراجعة إدارية/);
  assert.throws(() => act(imported, 'buySeed', { id: 'wheat', qty: 1 }), /مراجعة إدارية/);
  assert.throws(() => act(imported, 'claimAchievement', { id: 'first_plant' }), /مراجعة إدارية/);
  const renamed = act(imported, 'rename', { name: 'اسم جديد' });
  assert.equal(renamed.state.name, 'اسم جديد');
  assert.equal(renamed.state.legacyUnverified, true);
});

test('server rejects crafted-queue overflow', () => {
  const state = defaults('مزارع', now);
  state.level = 12;
  state.buildings = ['mill'];
  state.harvestedCrops.wheat = 100;
  state.activeCrafts = Array.from({ length: 20 }, (_, i) => ({
    id: 'flour_wheat', outputId: 'flour', qty: 1,
    readyAt: new Date(now.getTime() + (i + 100) * 1000).toISOString(),
  }));
  assert.throws(() => act(state, 'startCraft', { id: 'flour_wheat', qty: 1 }), /قائمة التصنيع ممتلئة/);
});

test('daily reward server amount matches the seven-day display contract', () => {
  const state = defaults('مزارع', now);
  const dayOne = act(state, 'claimDailyReward');
  assert.equal(dayOne.result.data.credited, 300);
  const tomorrow = new Date(now.getTime() + 86400000);
  const dayTwo = applyAction(dayOne.state, 'claimDailyReward', {}, tomorrow);
  assert.equal(dayTwo.result.data.credited, 350);
});
