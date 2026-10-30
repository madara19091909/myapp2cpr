'use strict';

const { randomInt } = require('node:crypto');

const LIMITS = Object.freeze({
  money: 2_000_000_000, gold: 1_000_000, stat: 1_000_000_000,
  stack: 500_000, products: 50_000, plots: 24,
});

const CROPS = Object.freeze({
  wheat: [7500, 1, 1200, 'القمح', '🌾'], lettuce: [14000, 2, 1500, 'الخس', '🥬'],
  corn: [22000, 3, 1800, 'الذرة', '🌽'], onion: [35000, 4, 2400, 'البصل', '🧅'],
  carrot: [52000, 5, 3000, 'الجزر', '🥕'], pepper: [80000, 7, 3600, 'الفلفل', '🫑'],
  cucumber: [110000, 8, 4200, 'الخيار', '🥒'], tomato: [200000, 11, 5400, 'الطماطم', '🍅'],
  eggplant: [280000, 13, 6600, 'الباذنجان', '🍆'], potato: [400000, 15, 7800, 'البطاطس', '🥔'],
  lemon: [720000, 19, 9600, 'الليمون', '🍋'], apple: [1300000, 24, 12000, 'التفاح', '🍎'],
  peach: [2000000, 27, 14400, 'الخوخ', '🍑'], orange: [3000000, 30, 16800, 'البرتقال', '🍊'],
  grape: [5000000, 36, 21600, 'العنب', '🍇'], watermelon: [7500000, 40, 25200, 'البطيخ', '🍉'],
  strawberry: [10000000, 43, 28800, 'الفراولة', '🍓'], berry: [16000000, 50, 36000, 'التوت', '🫐'],
  cherry: [30000000, 58, 43200, 'الكرز', '🍒'], pineapple: [55000000, 68, 54000, 'الأناناس', '🍍'],
  coconut: [95000000, 80, 64800, 'جوز الهند', '🥥'], mango: [160000000, 95, 86400, 'المانجو', '🥭'],
});
const ANIMALS = Object.freeze({
  chicken: [150000, 1500, true, 0, 'الدجاج'], rabbit: [250000, 1800, true, 0, 'الأرانب'],
  cow: [450000, 2400, true, 0, 'البقر'], goat: [600000, 2700, true, 0, 'الماعز'],
  sheep: [850000, 3000, true, 0, 'الغنم'], bees: [1100000, 2700, true, 0, 'النحل'],
  fish: [1800000, 3600, true, 0, 'السمك'], birds: [2800000, 4200, true, 0, 'الطيور'],
  camel: [5000000, 5400, true, 0, 'الجمال'],
  cat: [150000, 0, false, 1, 'القطط'], dog: [350000, 0, false, 2, 'الكلاب'],
  horse: [900000, 0, false, 3, 'الخيول'], peacock: [1800000, 0, false, 4, 'الطاووس'],
});
const TOOLS = Object.freeze({ axe: 25, bucket: 40, pickaxe: 55, boots: 30, hat: 20 });
const BUILDINGS = Object.freeze({
  greenhouse: [120000, 5, 0.06, 0, 0, 0], barn: [200000, 8, 0, 0, 8, 0],
  well: [90000, 4, 0, 0, 0, 30], silo: [150000, 10, 0, 3, 0, 0],
  mill: [250000, 12, 0, 0, 0, 0], bakery: [400000, 18, 0, 0, 0, 0],
  school: [180000, 7, 0, 0, 0, 0, 10], warehouse: [300000, 15, 0, 2, 0, 0],
});
const DECOR = Object.freeze({
  scarecrow: [25000, 3, 0, 1, 0], fence: [40000, 5, 0.02, 0, 0],
  lantern: [60000, 8, 0, 0, 4], fountain: [150000, 14, 0.03, 2, 0],
  statue: [280000, 20, 0, 3, 2], flowers: [90000, 10, 0, 1, 0],
  windmill: [350000, 25, 0.04, 0, 0], flag: [50000, 6, 0, 0, 2],
});
const RECIPES = Object.freeze({
  flour_wheat: ['wheat', 3, 'flour', 'دقيق', '🫓', 12100, 480, 12, 'mill'],
  flour_corn: ['corn', 2, 'corn_flour', 'دقيق ذرة', '🟡', 20900, 240, 12, 'mill'],
  bread: ['wheat', 5, 'bread', 'خبز', '🍞', 23100, 360, 18, 'bakery'],
  cake: ['strawberry', 2, 'cake', 'كعكة', '🍰', 6600000, 900, 45, 'bakery'],
  juice: ['orange', 2, 'juice', 'عصير', '🧃', 2090000, 480, 30, 'bakery'],
  jam_grape: ['grape', 2, 'jam', 'مربى', '🫙', 3850000, 240, 36, 'bakery'],
  chips: ['potato', 3, 'chips', 'شيبس', '🍟', 412500, 150, 15, 'mill'],
});
const MISSIONS = Object.freeze({
  plant_3: ['planted', 3, 150, 2, 'بداية خضراء'], harvest_3: ['harvested', 3, 200, 3, 'وقت الحصاد'],
  sell_3: ['sold', 3, 180, 2, 'تاجر ماهر'], water_2: ['watered', 2, 100, 2, 'ساقي المزرعة'],
  collect_1: ['animalCollections', 1, 150, 2, 'خير الحيوانات'],
});
const ACHIEVEMENTS = Object.freeze({
  first_plant: ['planted', 1, 400, 1, 'أول بذرة'], farmer_25: ['planted', 25, 1500, 1, 'مزارع مجتهد'],
  harvest_25: ['harvested', 25, 1800, 1, 'خبير الحصاد'], seller_25: ['sold', 25, 2000, 1, 'تاجر المزرعة'],
  level_5: ['level', 5, 2500, 2, 'مزارع متقدم'], water_10: ['watered', 10, 1000, 1, 'صديق الماء'],
  level_15: ['level', 15, 8000, 3, 'مزارع محترف'], animals_5: ['animalCollections', 20, 3500, 2, 'راعي القطيع'],
  builder_1: ['buildingsBought', 1, 1500, 1, 'بنّاء المزرعة'], builder_4: ['buildingsBought', 4, 10000, 3, 'مدينة زراعية'],
  crafter_10: ['crafted', 10, 4000, 2, 'حرفي ماهر'], level_30: ['level', 30, 20000, 5, 'أسطورة المزرعة'],
  decor_3: ['decorBought', 3, 5000, 2, 'مزرعة أنيقة'], lucky_7: ['luckyOpens', 7, 4000, 2, 'محظوظ'],
});

function bag(value) { return value && typeof value === 'object' && !Array.isArray(value) ? value : {}; }
function arr(value) { return Array.isArray(value) ? value : []; }
function n(value, fallback = 0) { return Number.isSafeInteger(value) ? value : fallback; }
function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }
function dateKey(date) {
  const p = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Baghdad', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(date);
  const m = Object.fromEntries(p.map(x => [x.type, x.value]));
  return `${m.year}-${m.month}-${m.day}`;
}
function localParts(date) {
  const p = new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Baghdad', year: 'numeric', month: 'numeric', day: 'numeric' }).formatToParts(date);
  return Object.fromEntries(p.map(x => [x.type, Number(x.value)]));
}
function marketPercent(cropId, date) {
  const p = localParts(date); const key = p.year * 10000 + p.month * 100 + p.day;
  let seed = key;
  [...cropId].forEach((ch, i) => { seed = (seed * 31 + ch.charCodeAt(0) * (i + 1)) & 0x7fffffff; });
  return 90 + seed % 13;
}
function weeklyEvent(date) {
  const p = localParts(date);
  const dayOfYear = Math.floor((Date.UTC(p.year, p.month - 1, p.day) - Date.UTC(p.year, 0, 1)) / 86400000);
  const week = Number(`${p.year}${Math.floor(dayOfYear / 7)}`);
  return [
    { sell: 2, grow: 1, xp: 0, crop: null }, { sell: 0, grow: .93, xp: 5, crop: null },
    { sell: 2, grow: .95, xp: 0, crop: 'wheat' }, { sell: 0, grow: 1, xp: 8, crop: null },
    { sell: 3, grow: 1.05, xp: 0, crop: null }, { sell: 0, grow: 1, xp: 0, crop: null },
  ][week % 6];
}
function weather(date) {
  const p = localParts(date); const key = p.year * 10000 + p.month * 100 + p.day; const idx = key % 5;
  return [
    { grow: .92, market: 0 }, { grow: 1, market: 0 }, { grow: .85, market: 5 },
    { grow: 1.25, market: -8 }, { grow: 1.15, market: 10 },
  ][idx];
}
function season(date) {
  const month = localParts(date).month;
  if (month >= 3 && month <= 5) return { sell: 5, xp: 10 };
  if (month >= 6 && month <= 8) return { sell: 0, xp: 0 };
  if (month >= 9 && month <= 11) return { sell: 8, xp: 5 };
  return { sell: -5, xp: 15 };
}
function defaults(name = 'المزارع', now = new Date()) {
  return {
    name, money: 18000, gold: 12, xp: 0, level: 1, seeds: {}, harvestedCrops: {}, animals: {},
    animalFeed: 0, waterUnits: 4, boostedCycles: {}, tools: [], buildings: [], decor: [], products: {},
    activeCrafts: [], transactions: [], dailyStreak: 0, luckyStreak: 0, dailyProgress: {},
    claimedDailyMissions: [], lifetimeStats: {}, claimedAchievements: [], collect: {},
    plots: Array.from({ length: 9 }, () => ({ crop: null, at: null, sec: 0, watered: false })),
    revision: 0, updated: now.getTime(), lastActiveAt: now.toISOString(),
  };
}
function sanitizeState(input, now = new Date()) {
  const d = defaults(typeof input?.name === 'string' ? input.name.slice(0, 24) : 'المزارع', now);
  if (!input || typeof input !== 'object') return d;
  for (const key of ['money', 'gold', 'xp', 'level', 'animalFeed', 'waterUnits', 'dailyStreak', 'luckyStreak']) {
    if (Number.isSafeInteger(input[key])) d[key] = input[key];
  }
  d.money = clamp(d.money, 0, LIMITS.money); d.gold = clamp(d.gold, 0, LIMITS.gold);
  d.xp = clamp(d.xp, 0, LIMITS.stat); d.level = clamp(d.level, 1, 1000000);
  d.animalFeed = clamp(d.animalFeed, 0, 1000000); d.waterUnits = clamp(d.waterUnits, 0, 1000000);
  d.dailyStreak = clamp(d.dailyStreak, 0, 7); d.luckyStreak = clamp(d.luckyStreak, 0, 1000000);
  for (const key of ['seeds', 'harvestedCrops', 'animals', 'boostedCycles', 'products', 'dailyProgress', 'lifetimeStats', 'collect']) d[key] = { ...bag(input[key]) };
  for (const key of ['tools', 'buildings', 'decor', 'claimedDailyMissions', 'claimedAchievements', 'transactions']) d[key] = arr(input[key]).slice(0, key === 'transactions' ? 60 : 100);
  // Craft queue entries are security-sensitive: only server-known recipes and
  // bounded quantities/timestamps may survive normalization.
  d.activeCrafts = arr(input.activeCrafts).slice(0, 20).flatMap(c => {
    if (!c || typeof c !== 'object' || !Object.hasOwn(RECIPES, c.id)) return [];
    const recipe = RECIPES[c.id];
    const amount = n(c.qty, 0);
    const readyAt = typeof c.readyAt === 'string' && Number.isFinite(Date.parse(c.readyAt)) ? c.readyAt : null;
    if (c.outputId !== recipe[2] || amount < 1 || amount > 20 || !readyAt) return [];
    return [{ id: c.id, name: recipe[3], emoji: recipe[4], outputId: recipe[2], outputName: recipe[3], qty: amount, readyAt }];
  });
  d.plots = arr(input.plots).slice(0, LIMITS.plots).map(p => ({
    crop: typeof p?.crop === 'string' && CROPS[p.crop] ? p.crop : null,
    at: typeof p?.at === 'string' && Number.isFinite(Date.parse(p.at)) ? p.at : null,
    sec: clamp(n(p?.sec), 0, 100000000), watered: p?.watered === true,
  }));
  if (d.plots.length < 9) d.plots.push(...Array.from({ length: 9 - d.plots.length }, () => ({ crop: null, at: null, sec: 0, watered: false })));
  d.tools = [...new Set(d.tools.filter(x => Object.hasOwn(TOOLS, x)))];
  d.buildings = [...new Set(d.buildings.filter(x => Object.hasOwn(BUILDINGS, x)))];
  d.decor = [...new Set(d.decor.filter(x => Object.hasOwn(DECOR, x)))];
  for (const key of Object.keys(d.seeds)) d.seeds[key] = clamp(n(d.seeds[key]), 0, LIMITS.stack);
  for (const key of Object.keys(d.harvestedCrops)) if (!CROPS[key]) delete d.harvestedCrops[key]; else d.harvestedCrops[key] = clamp(n(d.harvestedCrops[key]), 0, LIMITS.stack);
  for (const key of Object.keys(d.animals)) if (!ANIMALS[key]) delete d.animals[key]; else d.animals[key] = clamp(n(d.animals[key]), 0, 999);
  for (const key of Object.keys(d.products)) d.products[key] = clamp(n(d.products[key]), 0, LIMITS.products);
  for (const key of ['lastDailyRewardDate', 'lastLuckyDate', 'dailyProgressDate', 'insuranceUntil', 'lastActiveAt']) {
    if (typeof input[key] === 'string' && input[key].length <= 64) d[key] = input[key];
  }
  for (const [animalId, stamp] of Object.entries(bag(input.collect))) {
    if (Object.hasOwn(ANIMALS, animalId) && typeof stamp === 'string' && Number.isFinite(Date.parse(stamp))) d.collect[animalId] = stamp;
  }
  if (input.legacyUnverified === true) d.legacyUnverified = true;
  if (typeof input.legacyImportedAt === 'string') d.legacyImportedAt = input.legacyImportedAt;
  if (typeof input.lastOfflineRewardMessage === 'string') d.lastOfflineRewardMessage = input.lastOfflineRewardMessage;
  d.revision = clamp(n(input.revision), 0, LIMITS.stat);
  d.updated = now.getTime();
  return d;
}
function total(map) { return Object.values(bag(map)).reduce((a, b) => a + clamp(n(b), 0, LIMITS.stack), 0); }
function record(s, title, detail, money = 0, gold = 0, now = new Date()) {
  s.transactions.unshift({ title, detail, money, gold, at: now.toISOString() });
  s.transactions = s.transactions.slice(0, 60);
}
function credit(s, field, amount) {
  const max = field === 'money' ? LIMITS.money : LIMITS.gold;
  const paid = clamp(Math.floor(amount), 0, max - s[field]); s[field] += paid; return paid;
}
function track(s, stat, qty, now) {
  const today = dateKey(now);
  if (s.dailyProgressDate !== today) { s.dailyProgressDate = today; s.dailyProgress = {}; s.claimedDailyMissions = []; }
  s.dailyProgress[stat] = clamp(n(s.dailyProgress[stat]) + qty, 0, LIMITS.stat);
  s.lifetimeStats[stat] = clamp(n(s.lifetimeStats[stat]) + qty, 0, LIMITS.stat);
}
function addXp(s, amount, now) {
  s.xp = clamp(s.xp + Math.max(0, Math.floor(amount)), 0, LIMITS.stat);
  let gained = 0;
  while (s.xp >= 120 + s.level * 140 && gained < 10000 && s.level < 1000000) {
    s.xp -= 120 + s.level * 140; s.level++; credit(s, 'gold', 1); gained++;
  }
  if (gained) record(s, 'ترقية مستوى', `ارتفع مستواك إلى ${s.level}`, 0, gained, now);
  return gained;
}
function finishCrafts(s, now) {
  const pending = [];
  for (const c of s.activeCrafts) {
    if (Date.parse(c.readyAt) <= now.getTime()) {
      const qty = clamp(n(c.qty, 1), 1, 1000);
      s.products[c.outputId] = clamp(n(s.products[c.outputId]) + qty, 0, LIMITS.products);
      track(s, 'crafted', qty, now); record(s, 'انتهى التصنيع', c.name || 'منتج', 0, 0, now);
    } else pending.push(c);
  }
  s.activeCrafts = pending;
}
function bonuses(s, now) {
  const event = weeklyEvent(now), w = weather(now), se = season(now);
  const growBuilding = s.buildings.reduce((v, id) => v + (BUILDINGS[id]?.[2] || 0), 0);
  const growDecor = s.decor.reduce((v, id) => v + (DECOR[id]?.[2] || 0), 0);
  const sellBuilding = s.buildings.reduce((v, id) => v + (BUILDINGS[id]?.[3] || 0), 0);
  const sellDecor = s.decor.reduce((v, id) => v + (DECOR[id]?.[3] || 0), 0);
  const xpBuilding = s.buildings.reduce((v, id) => v + (BUILDINGS[id]?.[6] || 0), 0);
  const xpDecor = s.decor.reduce((v, id) => v + (DECOR[id]?.[4] || 0), 0);
  const animalBonus = s.buildings.reduce((v, id) => v + (BUILDINGS[id]?.[4] || 0), 0);
  const waterSave = Math.min(60, s.buildings.reduce((v, id) => v + (BUILDINGS[id]?.[5] || 0), 0));
  const petBonus = Math.min(100, Object.entries(s.animals).reduce((v, [id, q]) => v + (ANIMALS[id]?.[3] || 0) * q, 0));
  const insurance = Date.parse(s.insuranceUntil || '') > now.getTime();
  let weatherGrow = w.grow; if (s.tools.includes('hat') && weatherGrow > 1) weatherGrow = 1 + (weatherGrow - 1) * .4;
  let speed = (s.tools.includes('axe') ? .88 : 1) * (s.tools.includes('bucket') ? .8 : 1)
    * (1 - clamp(growBuilding + growDecor, 0, .5)) * weatherGrow * event.grow;
  speed = clamp(speed, .35, 1.45);
  return { event, weather: w, season: se, insurance, petBonus,
    sellBonus: sellBuilding + sellDecor + event.sell,
    xpBonus: xpBuilding + xpDecor + (s.tools.includes('boots') ? 10 : 0) + event.xp,
    animalBonus, waterSave, speed, yield: s.tools.includes('pickaxe') ? 2 : 1 };
}
function animalIncome(s, id, cycles, b) {
  const a = ANIMALS[id], count = n(s.animals[id]);
  if (!a || !a[2] || cycles <= 0) return 0;
  const incomePerCycle = clamp(Math.round(a[0] * .0018), 40, 999999999);
  const boosted = clamp(cycles, 0, n(s.boostedCycles[id]));
  const raw = (cycles - boosted) * incomePerCycle * count + Math.round(boosted * incomePerCycle * count * 1.5);
  return Math.round(raw * (100 + b.animalBonus) / 100);
}
function pendingCycles(s, id, now) {
  const a = ANIMALS[id]; if (!a || !a[2] || !n(s.animals[id])) return 0;
  const last = Date.parse(s.collect[id] || now.toISOString());
  return clamp(Math.floor(Math.max(0, (now.getTime() - last) / 1000) / a[1]), 0, 4);
}
function collectOne(s, id, now, b) {
  const cycles = pendingCycles(s, id, now); if (!cycles) return 0;
  const value = credit(s, 'money', animalIncome(s, id, cycles, b));
  const last = Date.parse(s.collect[id] || now.toISOString());
  s.collect[id] = (cycles >= 4 ? now : new Date(last + cycles * ANIMALS[id][1] * 1000)).toISOString();
  const boostedLeft = Math.max(0, n(s.boostedCycles[id]) - Math.min(cycles, n(s.boostedCycles[id])));
  if (boostedLeft) s.boostedCycles[id] = boostedLeft; else delete s.boostedCycles[id];
  record(s, 'تحصيل إنتاج الحيوانات', ANIMALS[id][4], value, 0, now); track(s, 'animalCollections', 1, now);
  return value;
}
function saleFee(s, gross, qty, b) {
  let rate = .03; if (s.plots.length >= 14) rate += .008; if (s.plots.length >= 18) rate += .007;
  if (total(s.animals) >= 6) rate += .005; rate = Math.min(.045, rate); if (b.insurance) rate *= .55;
  return clamp(Math.floor(gross * rate) + qty * 3, 15, gross);
}
function cropSalePrice(s, id, now, b) {
  const c = CROPS[id]; if (!c) return 0;
  const margin = c[1] <= 5 ? 1.28 : c[1] <= 20 ? 1.25 : 1.27;
  const base = Math.round(Math.round(c[0] * margin) * marketPercent(id, now) / 100);
  let bonus = b.petBonus + b.sellBonus + b.season.sell + (b.weather.market < 0 && b.insurance ? Math.round(b.weather.market / 2) : b.weather.market);
  if (b.event.crop === id) bonus += 4;
  return clamp(Math.round(base * (100 + clamp(bonus, -30, 15)) / 100), 1, LIMITS.money);
}
function productPrice(id, b) {
  const r = Object.values(RECIPES).find(x => x[2] === id); if (!r) return 0;
  const bonus = b.sellBonus + b.season.sell + (b.weather.market < 0 && b.insurance ? Math.round(b.weather.market / 2) : b.weather.market);
  return clamp(Math.round(r[5] * (100 + clamp(bonus, -25, 20)) / 100), 1, LIMITS.money);
}
function fail(message) { const e = new Error(message); e.code = 'failed-precondition'; throw e; }

function applyAction(input, action, args = {}, now = new Date()) {
  const s = sanitizeState(input, now); const a = bag(args); const b = bonuses(s, now);
  finishCrafts(s, now);
  if (s.legacyUnverified && !['refresh', 'rename'].includes(action)) {
    fail('حسابك القديم يحتاج مراجعة إدارية قبل استئناف عمليات المزرعة والاقتصاد.');
  }
  let data = {};
  const id = typeof a.id === 'string' ? a.id : '';
  const qty = clamp(n(a.qty, 1), 1, 9999);
  switch (action) {
    case 'rename': {
      const name = typeof a.name === 'string' ? a.name.trim().replace(/\s+/g, ' ').slice(0, 24) : '';
      if (!name) fail('الاسم غير صالح'); s.name = name; break;
    }
    case 'buyWater': {
      const packs = clamp(n(a.packs, 1), 1, 999), cost = 12000 * packs, units = 6 * packs;
      if (s.money < cost) fail('رصيدك غير كافٍ لشراء الماء');
      if (s.waterUnits > 1000000 - units) fail('مخزون الماء ممتلئ');
      s.money -= cost; s.waterUnits += units; record(s, 'شراء ماء للزراعة', `${units} وحدة ماء`, -cost, 0, now); break;
    }
    case 'waterPlot': {
      const i = n(a.index, -1), p = s.plots[i];
      if (!p || !p.crop || !p.at) fail('مساحة الزراعة غير صالحة');
      if (Date.parse(p.at) + p.sec * 1000 <= now.getTime()) fail('المحصول ناضج بالفعل؛ احصده أولاً');
      if (p.watered) fail('تم سقي هذا المحصول بالفعل'); if (s.waterUnits < 1) fail('ما عندك ماء كافي');
      const reduction = Math.round(p.sec * .25); if (reduction < 1) fail('هذا المحصول لا يحتاج إلى سقي إضافي');
      p.at = new Date(Date.parse(p.at) - reduction * 1000).toISOString(); p.watered = true;
      const saved = b.waterSave > 0 && randomInt(100) < b.waterSave; if (!saved) s.waterUnits--;
      track(s, 'watered', 1, now); record(s, 'سقي محصول', `${CROPS[p.crop][3]}: تقليل 25%${saved ? ' (البئر وفّر الماء)' : ''}`, 0, 0, now); break;
    }
    case 'unlockPlot': {
      const count = s.plots.length, price = 90000 + Math.max(0, count - 9) * 110000, required = 4 + ((count - 9 + 1) * 4);
      if (count >= 24) fail('وصلت للحد الأقصى لمساحات المزرعة'); if (s.level < required) fail(`تحتاج المستوى ${required} لفتح مساحة جديدة`);
      if (s.money < price) fail('رصيدك غير كافٍ لفتح مساحة جديدة'); s.money -= price; s.plots.push({ crop: null, at: null, sec: 0, watered: false });
      record(s, 'توسعة المزرعة', `فتح مساحة زراعة ${s.plots.length}`, -price, 0, now); break;
    }
    case 'buySeed': {
      const c = CROPS[id]; if (!c) fail('هذا المحصول غير موجود');
      const amount = clamp(n(a.qty, 1), 1, 25), cost = c[0] * amount;
      if (s.level < c[1]) fail(`يتطلب المستوى ${c[1]}`); if (s.money < cost) fail('رصيدك غير كافٍ 💸');
      if (n(s.seeds[id]) > LIMITS.stack - amount) fail('مخزون هذه البذور ممتلئ');
      s.money -= cost; s.seeds[id] = n(s.seeds[id]) + amount; record(s, 'شراء بذور', `${amount} × ${c[3]}`, -cost, 0, now); break;
    }
    case 'sellSeed': {
      const c = CROPS[id]; if (!c) fail('هذا المحصول غير موجود'); if (qty > 9999 || n(s.seeds[id]) < qty) fail('ما عندك كمية كافية للبيع');
      const unit = Math.floor(c[0] * .6); if (!unit) fail('لا يمكن بيع هذا العنصر حالياً');
      s.seeds[id] -= qty; if (!s.seeds[id]) delete s.seeds[id]; const paid = credit(s, 'money', unit * qty);
      record(s, 'بيع بذور', `${qty} × ${c[3]}`, paid, 0, now); break;
    }
    case 'buyAnimal': {
      const animal = ANIMALS[id]; if (!animal) fail('بيانات الحيوان غير صالحة'); if (s.money < animal[0]) fail('رصيدك غير كافٍ 💸');
      if (animal[2] && n(s.animals[id]) > 0) collectOne(s, id, now, b);
      if (n(s.animals[id]) >= 999) fail('وصلت إلى الحد الأقصى من هذا الحيوان');
      s.money -= animal[0]; if (animal[2] && !n(s.animals[id])) s.collect[id] = now.toISOString();
      s.animals[id] = n(s.animals[id]) + 1; record(s, 'شراء حيوان', animal[4], -animal[0], 0, now); break;
    }
    case 'sellAnimal': {
      const animal = ANIMALS[id]; if (!animal || n(s.animals[id]) < qty || qty > 99) fail('ما عندك عدد كافي للبيع');
      if (animal[2]) collectOne(s, id, now, b);
      const refund = Math.floor(animal[0] * .5) * qty; s.animals[id] -= qty; if (!s.animals[id]) { delete s.animals[id]; delete s.collect[id]; delete s.boostedCycles[id]; }
      const paid = credit(s, 'money', refund); record(s, 'بيع حيوان', `${qty} × ${animal[4]}`, paid, 0, now); break;
    }
    case 'buyAnimalFeed': {
      const packs = clamp(n(a.packs, 1), 1, 999), cost = 45000 * packs, units = 3 * packs;
      if (s.money < cost) fail('رصيدك غير كافٍ لشراء العلف'); if (s.animalFeed > 1000000 - units) fail('مخزون العلف ممتلئ');
      s.money -= cost; s.animalFeed += units; record(s, 'شراء علف الحيوانات', `${packs} كيس (${units} وحدات)`, -cost, 0, now); break;
    }
    case 'feedAnimal': {
      const animal = ANIMALS[id]; const count = n(s.animals[id]); if (!animal || !animal[2] || !count) fail('اشترِ هذا الحيوان أولاً');
      if (s.animalFeed < count) fail(`العلف غير كافٍ؛ تحتاج ${count} وحدة`); collectOne(s, id, now, b);
      s.collect[id] = now.toISOString(); s.animalFeed -= count; s.boostedCycles[id] = clamp(n(s.boostedCycles[id]) + 3, 0, 30);
      record(s, 'إطعام الحيوانات', `${animal[4]}: ${count} حيوان، تعزيز 50% لثلاث دورات`, 0, 0, now); break;
    }
    case 'buyTool': {
      if (!Object.hasOwn(TOOLS, id)) fail('الأداة غير موجودة'); if (s.tools.includes(id)) fail('تملك هذه الأداة بالفعل');
      if (s.gold < TOOLS[id]) fail('عملاتك الذهبية غير كافية 🪙'); s.gold -= TOOLS[id]; s.tools.push(id); record(s, 'شراء أداة', id, 0, -TOOLS[id], now); break;
    }
    case 'buyBuilding': {
      const item = BUILDINGS[id]; if (!item) fail('المبنى غير موجود'); if (s.buildings.includes(id)) fail('تملك هذا المبنى بالفعل');
      if (s.level < item[1]) fail(`يتطلب المستوى ${item[1]}`); if (s.money < item[0]) fail('رصيدك غير كافٍ');
      s.money -= item[0]; s.buildings.push(id); track(s, 'buildingsBought', 1, now); s.lifetimeStats.buildingsBought = s.buildings.length;
      record(s, 'شراء مبنى', id, -item[0], 0, now); break;
    }
    case 'buyDecor': {
      const item = DECOR[id]; if (!item) fail('الديكور غير موجود'); if (s.decor.includes(id)) fail('تملك هذا الديكور بالفعل');
      if (s.level < item[1]) fail(`يتطلب المستوى ${item[1]}`); if (s.money < item[0]) fail('رصيدك غير كافٍ');
      s.money -= item[0]; s.decor.push(id); track(s, 'decorBought', 1, now); s.lifetimeStats.decorBought = s.decor.length;
      record(s, 'شراء ديكور', id, -item[0], 0, now); break;
    }
    case 'buyInsurance': {
      if (b.insurance) fail('تأمينك ساري بالفعل'); if (s.money < 55000) fail('رصيدك غير كافٍ لشراء التأمين');
      s.money -= 55000; s.insuranceUntil = new Date(now.getTime() + 5 * 86400000).toISOString(); record(s, 'تأمين المزرعة', 'تغطية 5 أيام', -55000, 0, now); break;
    }
    case 'plant': {
      const crop = CROPS[id], i = n(a.index, -1), p = s.plots[i]; if (!crop || !p) fail('مساحة أو محصول غير صالح');
      if (s.level < crop[1]) fail(`يتطلب المستوى ${crop[1]}`); if (p.crop) fail('المساحة مشغولة'); if (n(s.seeds[id]) < 1) fail('لا تملك بذوراً كافية');
      s.seeds[id]--; if (!s.seeds[id]) delete s.seeds[id]; p.crop = id; p.at = now.toISOString(); p.sec = Math.max(3, Math.ceil(crop[2] * b.speed)); p.watered = false;
      track(s, 'planted', 1, now); break;
    }
    case 'harvest': {
      const indexes = a.all === true ? s.plots.map((_, i) => i) : [n(a.index, -1)]; let totalXp = 0, harvestedCount = 0;
      for (const i of indexes) {
        const p = s.plots[i]; if (!p?.crop || !p.at || Date.parse(p.at) + p.sec * 1000 > now.getTime()) continue;
        const cropId = p.crop, c = CROPS[cropId]; if (!c) { s.plots[i] = { crop: null, at: null, sec: 0, watered: false }; continue; }
        const available = LIMITS.stack - n(s.harvestedCrops[cropId]); if (available <= 0) continue;
        const amount = Math.min(b.yield, available); s.harvestedCrops[cropId] = n(s.harvestedCrops[cropId]) + amount;
        track(s, 'harvested', amount, now); record(s, 'حصاد محصول', `${c[4]} ${c[3]} ×${amount}`, 0, 0, now);
        const xp = 2 + Math.floor(c[1] / 2) + Math.floor(c[2] / 700);
        totalXp += Math.round(xp * (100 + b.xpBonus + b.season.xp) / 100); harvestedCount += amount;
        s.plots[i] = { crop: null, at: null, sec: 0, watered: false };
      }
      if (!harvestedCount) fail('لا توجد محاصيل ناضجة أو أن المخزن ممتلئ');
      const levelsGained = addXp(s, totalXp, now); data = { harvestedCount, xp: totalXp, levelsGained }; break;
    }
    case 'sellCrop':
    case 'sellAllCrops': {
      const sold = {};
      if (action === 'sellCrop') { if (!CROPS[id] || qty > 100 || n(s.harvestedCrops[id]) < qty) fail('الكمية المخزونة غير كافية'); sold[id] = qty; }
      else for (const [cropId, amount] of Object.entries(s.harvestedCrops)) if (CROPS[cropId] && n(amount) > 0) sold[cropId] = n(amount);
      const entries = Object.entries(sold); if (!entries.length) fail('ما عندك محاصيل مخزونة للبيع');
      const count = entries.reduce((v, [, amount]) => v + amount, 0);
      if (action === 'sellAllCrops' && count > 5000) fail('بع المحاصيل على دفعات حتى لا تتجاوز الحد');
      const gross = entries.reduce((v, [cropId, amount]) => v + cropSalePrice(s, cropId, now, b) * amount, 0);
      const tax = Math.floor(gross * .15), fee = saleFee(s, gross, count, b), net = Math.max(0, gross - tax - fee);
      if (net < 1) fail('بعد الضريبة ورسوم التشغيل لا يتبقى ربح'); if (net > LIMITS.money - s.money) fail('رصيدك قريب من الحد الأقصى');
      entries.forEach(([cropId, amount]) => { s.harvestedCrops[cropId] -= amount; if (!s.harvestedCrops[cropId]) delete s.harvestedCrops[cropId]; });
      s.money += net; track(s, 'sold', count, now); record(s, 'بيع محاصيل مخزونة', `${count} محصول (ضريبة ${tax} + تشغيل ${fee})`, net, 0, now);
      data = { credited: net, soldCount: count, tax, fee }; break;
    }
    case 'collectAnimal':
    case 'collectAllAnimals': {
      const ids = action === 'collectAllAnimals' ? Object.keys(ANIMALS).filter(x => ANIMALS[x][2]) : [id];
      let totalPaid = 0; ids.forEach(animalId => { if (!ANIMALS[animalId]) return; totalPaid += collectOne(s, animalId, now, b); });
      data = { credited: totalPaid }; break;
    }
    case 'startCraft': {
      const recipe = RECIPES[id]; if (!recipe) fail('الوصفة غير موجودة'); const amount = clamp(n(a.qty, 1), 1, 20);
      if (s.activeCrafts.length >= 20) fail('قائمة التصنيع ممتلئة؛ انتظر اكتمال بعض الطلبات أولاً');
      if (!s.buildings.includes(recipe[8])) fail('تحتاج المبنى المخصص لهذه الوصفة أولاً'); if (s.level < recipe[7]) fail(`يتطلب المستوى ${recipe[7]}`);
      const need = recipe[1] * amount; if (n(s.harvestedCrops[recipe[0]]) < need) fail('المحاصيل غير كافية للتصنيع');
      s.harvestedCrops[recipe[0]] -= need; if (!s.harvestedCrops[recipe[0]]) delete s.harvestedCrops[recipe[0]];
      s.activeCrafts.push({ id, name: id, emoji: '⚙️', outputId: recipe[2], outputName: recipe[3], qty: amount, readyAt: new Date(now.getTime() + recipe[6] * amount * 1000).toISOString() });
      record(s, 'بدء تصنيع', `${id} ×${amount}`, 0, 0, now); break;
    }
    case 'sellProduct': {
      if (qty > 100 || n(s.products[id]) < qty) fail('الكمية غير كافية'); const unit = productPrice(id, b); if (!unit) fail('منتج غير معروف');
      const gross = unit * qty, tax = Math.floor(gross * .15), fee = saleFee(s, gross, qty, b), net = Math.max(0, gross - tax - fee);
      if (net < 1 || net > LIMITS.money - s.money) fail('تعذر إتمام البيع بسبب حدود الرصيد');
      s.products[id] -= qty; if (!s.products[id]) delete s.products[id]; s.money += net; track(s, 'sold', qty, now);
      record(s, 'بيع منتج مصنّع', `${id} ×${qty} (ضريبة ${tax} + رسوم ${fee})`, net, 0, now); data = { credited: net, tax, fee }; break;
    }
    case 'claimDailyReward': {
      const today = dateKey(now); if (s.lastDailyRewardDate === today) fail('استلمت مكافأتك اليومية بالفعل');
      const yesterday = dateKey(new Date(now.getTime() - 86400000)); s.dailyStreak = s.lastDailyRewardDate === yesterday ? (s.dailyStreak % 7) + 1 : 1;
      const cash = credit(s, 'money', 300 + (s.dailyStreak - 1) * 50), gold = s.dailyStreak === 7 ? credit(s, 'gold', 1) : 0;
      s.lastDailyRewardDate = today; record(s, 'المكافأة اليومية', `اليوم ${s.dailyStreak} من 7`, cash, gold, now); data = { credited: cash, gold }; break;
    }
    case 'claimLuckyChest': {
      const today = dateKey(now); if (s.lastLuckyDate === today) fail('استلمت صندوق الحظ اليوم بالفعل');
      const yesterday = dateKey(new Date(now.getTime() - 86400000)); s.luckyStreak = s.lastLuckyDate === yesterday ? s.luckyStreak + 1 : 1; s.lastLuckyDate = today; track(s, 'luckyOpens', 1, now);
      const roll = randomInt(100); let message;
      if (roll < 8) { const g = credit(s, 'gold', 1 + Math.floor(s.luckyStreak / 7)); message = `صندوق ذهبي! +${g} ذهب 🪙`; }
      else if (roll < 35) { const c = credit(s, 'money', 400 + s.level * 25 + s.luckyStreak * 20); message = `كيس فلوس! +${c} دينار 💵`; }
      else if (roll < 55) { s.waterUnits = clamp(s.waterUnits + 2, 0, 1000000); message = 'عبوات ماء! +2 ماء 💧'; }
      else if (roll < 70) { s.animalFeed = clamp(s.animalFeed + 1, 0, 1000000); message = 'علف مجاني! +1 علف 🌽'; }
      else { const c = credit(s, 'money', 200 + s.level * 15); message = `حظ عادي +${c} دينار`; }
      record(s, 'صندوق الحظ', message, 0, 0, now); data = { message }; break;
    }
    case 'claimDailyMission': {
      if (s.legacyUnverified) fail('حسابك القديم يحتاج مراجعة إدارية قبل استلام مكافآت المهام.');
      const m = MISSIONS[id]; if (!m) fail('المهمة غير موجودة');
      if (s.dailyProgressDate !== dateKey(now)) { s.dailyProgressDate = dateKey(now); s.dailyProgress = {}; s.claimedDailyMissions = []; }
      if (s.claimedDailyMissions.includes(id)) fail('استلمت مكافأة هذه المهمة اليوم'); if (n(s.dailyProgress[m[0]]) < m[1]) fail('أكمل المهمة أولاً حتى تستلم المكافأة');
      const cash = credit(s, 'money', m[2]); s.claimedDailyMissions.push(id); record(s, 'مكافأة مهمة يومية', m[4], cash, 0, now); addXp(s, m[3], now); break;
    }
    case 'claimAchievement': {
      if (s.legacyUnverified) fail('حسابك القديم يحتاج مراجعة إدارية قبل استلام مكافآت الإنجازات.');
      const ach = ACHIEVEMENTS[id]; if (!ach) fail('الإنجاز غير موجود'); if (s.claimedAchievements.includes(id)) fail('استلمت مكافأة هذا الإنجاز سابقاً');
      const progress = ach[0] === 'level' ? s.level : n(s.lifetimeStats[ach[0]]); if (progress < ach[1]) fail('أكمل شروط الإنجاز أولاً');
      const cash = credit(s, 'money', ach[2]), gold = credit(s, 'gold', ach[3]); s.claimedAchievements.push(id); record(s, 'مكافأة إنجاز', ach[4], cash, gold, now); break;
    }
    case 'refresh': {
      const last = Date.parse(s.lastActiveAt || '');
      if (Number.isFinite(last)) {
        const hours = Math.floor((now.getTime() - last) / 3600000);
        if (hours >= 2) {
          const capped = clamp(hours, 4, 10);
          const cash = credit(s, 'money', clamp(s.level * 25 * capped, 0, 8000));
          s.lastOfflineRewardMessage = `مرحباً بعودتك! حصلت على ${cash} دينار عن ${capped} ساعة غياب`;
          record(s, 'مكافأة العودة', s.lastOfflineRewardMessage, cash, 0, now);
          data = { offlineReward: s.lastOfflineRewardMessage };
        }
      }
      break;
    }
    default: fail('عملية غير معروفة');
  }
  s.revision = clamp(n(s.revision) + 1, 0, LIMITS.stat);
  s.updated = now.getTime(); s.lastActiveAt = now.toISOString();
  return { state: s, result: { ok: true, data } };
}

function importLegacyState(oldState, now = new Date()) {
  const state = sanitizeState(oldState, now);
  // Historical balances/assets cannot be authenticated retrospectively. Preserve
  // progression for continuity, but neutralize every client-controlled timer/queue
  // before the state becomes server-authoritative.
  state.legacyUnverified = true;
  state.legacyImportedAt = now.toISOString();
  state.lastActiveAt = now.toISOString();
  state.lastDailyRewardDate = dateKey(now);
  state.dailyStreak = 0;
  state.lastLuckyDate = dateKey(now);
  state.luckyStreak = 0;
  state.dailyProgressDate = dateKey(now);
  state.dailyProgress = {};
  state.claimedDailyMissions = [];
  state.insuranceUntil = null;
  state.activeCrafts = [];
  const b = bonuses(state, now);
  state.plots = state.plots.map(plot => plot.crop && CROPS[plot.crop] ? {
    crop: plot.crop, at: now.toISOString(),
    sec: Math.max(3, Math.ceil(CROPS[plot.crop][2] * b.speed)), watered: false,
  } : { crop: null, at: null, sec: 0, watered: false });
  for (const [animalId, animal] of Object.entries(ANIMALS)) {
    if (animal[2] && n(state.animals[animalId]) > 0) state.collect[animalId] = now.toISOString();
    else delete state.collect[animalId];
  }
  state.boostedCycles = {};
  state.updated = now.getTime();
  return state;
}

module.exports = { LIMITS, defaults, sanitizeState, applyAction, importLegacyState, dateKey, CROPS, ANIMALS };
