import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../buildings/data/building_data.dart';
import '../../decor/data/decor_data.dart';
import '../../events/weekly_event.dart';
import '../../shop/data/shop_data.dart';
import '../../shop/models/animal.dart';
import '../../shop/models/crop.dart';
import '../../shop/models/tool_item.dart';
import '../models/plot.dart';
import '../models/weather.dart';

class HarvestResult {
  const HarvestResult({required this.income, required this.xp, required this.levelsGained, this.harvestedCount = 0});

  /// يبقى صفراً عند الحصاد لأن البيع صار خطوة مستقلة من المخزن.
  final int income;
  final int xp;
  final int levelsGained;
  final int harvestedCount;
}

class GameState extends ChangeNotifier {
  static const _saveKey = 'farm_party_save_v1';
  static const int maxStoredCycles = 4;
  static const int levelUpGoldReward = 1;
  static const int startingPlotCount = 9;
  static const int maxPlotCount = 24;
  static const int maxItemStack = 500000;
  static const int maxProducts = 50000;
  static const int maxSeedBuyPerAction = 25;
  static const int maxSellPerAction = 100;
  static const int salesTaxPercent = 15;
  static const int insurancePrice = 55000;
  static const int insuranceDays = 5;

  // حدود الموارد
  static const int maxMoney = 2000000000;
  static const int maxGold = 1000000;
  static const int maxWater = 1000000;
  static const int maxFeed = 1000000;
  static const int maxLevel = 1000000;
  static const int maxStat = 1000000000;

  static const int waterPackSize = 6;
  static const int waterPackPrice = 12000;
  static const int animalFeedPackSize = 3;
  static const int animalFeedPackPrice = 45000;

  /// اللعبة تعتمد على الوقت المحلي للتشغيل، ولا تحتاج إلى اتصال بالخادم لتنفيذ الأفعال.
  DateTime get serverNow => DateTime.now();
  DateTime get baghdadNow => DateTime.now().toUtc().add(const Duration(hours: 3));

  /// حقل توافق مع الحفظ القديم؛ لا يوقف التقدم في نمط اللعب المحلي.
  bool legacyUnverified = false;
  String? legacyImportedAt;
  int _stateUpdatedAt = DateTime.now().millisecondsSinceEpoch;

  String playerName = 'المزارع';
  int money = 18000;
  int gold = 12;
  int xp = 0;
  int level = 1;

  final Map<String, int> seeds = {};

  /// المحاصيل التي تم حصادها ولم تُبع بعد.
  final Map<String, int> harvestedCrops = {};
  final Map<String, int> animals = {};
  final Set<String> tools = {};
  final Set<String> ownedBuildings = {};
  final Set<String> ownedDecor = {};
  final Map<String, int> products = {};
  final List<Map<String, dynamic>> activeCrafts = [];
  String? lastLuckyDate;
  int luckyStreak = 0;
  DateTime? insuranceUntil;
  bool _economyBusy = false;
  final Map<String, DateTime> _lastCollect = {};
  int animalFeed = 0;
  int waterUnits = 4;
  final Map<String, int> _boostedCycles = {};
  List<Plot> plots = List.generate(startingPlotCount, (_) => Plot());
  final List<Map<String, dynamic>> transactions = [];
  String? lastDailyRewardDate;
  int dailyStreak = 0;
  DateTime? lastActiveAt;
  String? lastOfflineRewardMessage;

  /// سبب فشل آخر عملية حصاد (مثلاً المخزن ممتلئ). يكون null إذا نجحت أو لم يكن هناك شيء جاهز.
  String? lastHarvestError;

  // تقدم المهام والإنجازات محفوظ محلياً مع ملف اللاعب.
  String? dailyProgressDate;
  final Map<String, int> dailyProgress = {};
  final Set<String> claimedDailyMissions = {};
  final Map<String, int> lifetimeStats = {};
  final Set<String> claimedAchievements = {};

  static const List<Map<String, dynamic>> dailyMissionDefinitions = [
    {'id': 'plant_3', 'title': 'بداية خضراء', 'description': 'ازرع 3 بذور اليوم', 'stat': 'planted', 'target': 3, 'money': 150, 'xp': 2, 'icon': '🌱'},
    {'id': 'harvest_3', 'title': 'وقت الحصاد', 'description': 'احصد 3 محاصيل اليوم', 'stat': 'harvested', 'target': 3, 'money': 200, 'xp': 3, 'icon': '🌾'},
    {'id': 'sell_3', 'title': 'تاجر ماهر', 'description': 'بع 3 محاصيل اليوم', 'stat': 'sold', 'target': 3, 'money': 180, 'xp': 2, 'icon': '🪙'},
    {'id': 'water_2', 'title': 'ساقي المزرعة', 'description': 'اسقِ محصولين اليوم', 'stat': 'watered', 'target': 2, 'money': 100, 'xp': 2, 'icon': '💧'},
    {'id': 'collect_1', 'title': 'خير الحيوانات', 'description': 'حصّل إنتاج الحيوانات مرة', 'stat': 'animalCollections', 'target': 1, 'money': 150, 'xp': 2, 'icon': '🐄'},
  ];

  static const List<Map<String, dynamic>> achievementDefinitions = [
    {'id': 'first_plant', 'title': 'أول بذرة', 'description': 'ازرع أول محصول في مزرعتك', 'stat': 'planted', 'target': 1, 'money': 400, 'gold': 1, 'icon': '🌱'},
    {'id': 'farmer_25', 'title': 'مزارع مجتهد', 'description': 'ازرع 25 بذرة بالمجموع', 'stat': 'planted', 'target': 25, 'money': 1500, 'gold': 1, 'icon': '🚜'},
    {'id': 'harvest_25', 'title': 'خبير الحصاد', 'description': 'احصد 25 محصولاً بالمجموع', 'stat': 'harvested', 'target': 25, 'money': 1800, 'gold': 1, 'icon': '🌾'},
    {'id': 'seller_25', 'title': 'تاجر المزرعة', 'description': 'بع 25 محصولاً بالمجموع', 'stat': 'sold', 'target': 25, 'money': 2000, 'gold': 1, 'icon': '💰'},
    {'id': 'level_5', 'title': 'مزارع متقدم', 'description': 'وصل إلى المستوى الخامس', 'stat': 'level', 'target': 5, 'money': 2500, 'gold': 2, 'icon': '🏆'},
    {'id': 'water_10', 'title': 'صديق الماء', 'description': 'اسقِ 10 محاصيل بالمجموع', 'stat': 'watered', 'target': 10, 'money': 1000, 'gold': 1, 'icon': '💧'},
    {'id': 'level_15', 'title': 'مزارع محترف', 'description': 'وصل إلى المستوى 15', 'stat': 'level', 'target': 15, 'money': 8000, 'gold': 3, 'icon': '⭐'},
    {'id': 'animals_5', 'title': 'راعي القطيع', 'description': 'حصّل إنتاج الحيوانات 20 مرة', 'stat': 'animalCollections', 'target': 20, 'money': 3500, 'gold': 2, 'icon': '🐄'},
    {'id': 'builder_1', 'title': 'بنّاء المزرعة', 'description': 'اشترِ أول مبنى', 'stat': 'buildingsBought', 'target': 1, 'money': 1500, 'gold': 1, 'icon': '🏗️'},
    {'id': 'builder_4', 'title': 'مدينة زراعية', 'description': 'امتلك 4 مباني', 'stat': 'buildingsBought', 'target': 4, 'money': 10000, 'gold': 3, 'icon': '🏙️'},
    {'id': 'crafter_10', 'title': 'حرفي ماهي', 'description': 'أنهِ 10 عمليات تصنيع', 'stat': 'crafted', 'target': 10, 'money': 4000, 'gold': 2, 'icon': '⚙️'},
    {'id': 'level_30', 'title': 'أسطورة المزرعة', 'description': 'وصل إلى المستوى 30', 'stat': 'level', 'target': 30, 'money': 20000, 'gold': 5, 'icon': '👑'},
    {'id': 'decor_3', 'title': 'مزرعة أنيقة', 'description': 'اشترِ 3 قطع ديكور', 'stat': 'decorBought', 'target': 3, 'money': 5000, 'gold': 2, 'icon': '🌹'},
    {'id': 'lucky_7', 'title': 'محظوظ', 'description': 'افتح صندوق الحظ 7 أيام متفرقة', 'stat': 'luckyOpens', 'target': 7, 'money': 4000, 'gold': 2, 'icon': '🎁'},
  ];

  // ---------- أدوات مساعدة ----------
  bool get canClaimDailyReward => lastDailyRewardDate != _dateKey(baghdadNow);

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _creditMoney(int requested) {
    if (requested <= 0) return 0;
    final remaining = (maxMoney - money).clamp(0, maxMoney).toInt();
    final credited = requested.clamp(0, remaining).toInt();
    money += credited;
    return credited;
  }

  int _creditGold(int requested) {
    if (requested <= 0) return 0;
    final remaining = (maxGold - gold).clamp(0, maxGold).toInt();
    final credited = requested.clamp(0, remaining).toInt();
    gold += credited;
    return credited;
  }

  void _record(String title, String detail, {int moneyDelta = 0, int goldDelta = 0}) {
    transactions.insert(0, {
      'title': title,
      'detail': detail,
      'money': moneyDelta,
      'gold': goldDelta,
      'at': DateTime.now().toIso8601String(),
    });
    if (transactions.length > 60) transactions.removeRange(60, transactions.length);
  }

  /// يضيف XP ويسجل الترقية بالسجل إن حصلت. يرجع عدد المستويات المكتسبة.
  int _grantXp(int amount) {
    final gained = _addXp(amount);
    if (gained > 0) _record('ترقية مستوى', 'ارتفع مستواك إلى $level', goldDelta: gained * levelUpGoldReward);
    return gained;
  }

  // ---------- المكافأة اليومية ----------
  Future<String?> claimDailyReward() async {
    if (!canClaimDailyReward) return 'استلمت مكافأتك اليومية بالفعل';
    final now = DateTime.now();
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    // مسار الـ 7 أيام يدور؛ اليوم السابع لا يجب أن يبقى قابلاً للاستلام للأبد.
    dailyStreak = lastDailyRewardDate == yesterday ? (dailyStreak % 7) + 1 : 1;
    final cashReward = 300 + (dailyStreak - 1) * 50;
    final goldReward = dailyStreak == 7 ? 1 : 0;
    final creditedCash = _creditMoney(cashReward);
    final creditedGold = _creditGold(goldReward);
    lastDailyRewardDate = _dateKey(now);
    _record('المكافأة اليومية', 'اليوم $dailyStreak من 7', moneyDelta: creditedCash, goldDelta: creditedGold);
    _commit();
    return null;
  }

  // ---------- المهام اليومية والإنجازات ----------
  void _ensureDailyProgressDate() {
    final today = _dateKey(baghdadNow);
    if (dailyProgressDate == today) return;
    dailyProgressDate = today;
    dailyProgress.clear();
    claimedDailyMissions.clear();
  }

  void _trackProgress(String stat, [int amount = 1]) {
    if (amount <= 0) return;
    _ensureDailyProgressDate();
    dailyProgress[stat] = ((dailyProgress[stat] ?? 0) + amount).clamp(0, maxStat).toInt();
    lifetimeStats[stat] = ((lifetimeStats[stat] ?? 0) + amount).clamp(0, maxStat).toInt();
  }

  int dailyMissionProgress(Map<String, dynamic> mission) {
    if (dailyProgressDate != _dateKey(DateTime.now())) return 0;
    return dailyProgress[mission['stat'] as String] ?? 0;
  }

  bool isDailyMissionClaimed(String id) =>
      dailyProgressDate == _dateKey(baghdadNow) && claimedDailyMissions.contains(id);

  bool canClaimDailyMission(Map<String, dynamic> mission) =>
      !isDailyMissionClaimed(mission['id'] as String) &&
      dailyMissionProgress(mission) >= (mission['target'] as int);

  static Map<String, dynamic>? _findDefinition(List<Map<String, dynamic>> list, String id) {
    for (final item in list) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  Future<String?> claimDailyMission(String id) async {
    _ensureDailyProgressDate();
    final mission = _findDefinition(dailyMissionDefinitions, id);
    if (mission == null) return 'المهمة غير موجودة';
    if (claimedDailyMissions.contains(id)) return 'استلمت مكافأة هذه المهمة اليوم';
    if (dailyMissionProgress(mission) < (mission['target'] as int)) return 'أكمل المهمة أولاً حتى تستلم المكافأة';
    final credited = _creditMoney(mission['money'] as int);
    claimedDailyMissions.add(id);
    _record('مكافأة مهمة يومية', mission['title'] as String, moneyDelta: credited);
    _grantXp(mission['xp'] as int);
    _commit();
    return null;
  }

  int achievementProgress(Map<String, dynamic> achievement) {
    if (achievement['stat'] == 'level') return level;
    return lifetimeStats[achievement['stat'] as String] ?? 0;
  }

  bool isAchievementClaimed(String id) => claimedAchievements.contains(id);

  bool canClaimAchievement(Map<String, dynamic> achievement) =>
      !claimedAchievements.contains(achievement['id'] as String) &&
      achievementProgress(achievement) >= (achievement['target'] as int);

  Future<String?> claimAchievement(String id) async {
    final achievement = _findDefinition(achievementDefinitions, id);
    if (achievement == null) return 'الإنجاز غير موجود';
    if (claimedAchievements.contains(id)) return 'استلمت مكافأة هذا الإنجاز سابقاً';
    if (achievementProgress(achievement) < (achievement['target'] as int)) return 'أكمل شروط الإنجاز أولاً';
    final cash = _creditMoney(achievement['money'] as int);
    final creditedGold = _creditGold(achievement['gold'] as int);
    claimedAchievements.add(id);
    _record('مكافأة إنجاز', achievement['title'] as String, moneyDelta: cash, goldDelta: creditedGold);
    _commit();
    return null;
  }

  // ---------- مشتقات ----------
  int get xpNeeded => 120 + (level * 140);

  WeatherInfo get weather => WeatherInfo.forDate(baghdadNow);
  SeasonInfo get season => SeasonInfo.current(baghdadNow);
  WeeklyEvent get weeklyEvent => WeeklyEvent.current(baghdadNow);

  bool hasBuilding(String id) => ownedBuildings.contains(id);
  bool hasDecor(String id) => ownedDecor.contains(id);

  double get _buildingGrowBonus {
    var b = 0.0;
    for (final id in ownedBuildings) {
      final def = BuildingData.tryById(id);
      if (def != null) b += def.growSpeedBonus;
    }
    for (final id in ownedDecor) {
      final d = DecorData.tryById(id);
      if (d != null) b += d.growBonus;
    }
    return b.clamp(0.0, 0.50);
  }

  int get buildingSellBonus {
    var b = 0;
    for (final id in ownedBuildings) {
      final def = BuildingData.tryById(id);
      if (def != null) b += def.sellBonusPercent;
    }
    for (final id in ownedDecor) {
      final d = DecorData.tryById(id);
      if (d != null) b += d.sellBonusPercent;
    }
    b += weeklyEvent.sellBonusPercent;
    return b;
  }

  int get buildingAnimalBonus {
    var b = 0;
    for (final id in ownedBuildings) {
      final def = BuildingData.tryById(id);
      if (def != null) b += def.animalIncomeBonus;
    }
    return b;
  }

  int get buildingXpBonus {
    var b = 0;
    for (final id in ownedBuildings) {
      final def = BuildingData.tryById(id);
      if (def != null) b += def.xpBonusPercent;
    }
    for (final id in ownedDecor) {
      final d = DecorData.tryById(id);
      if (d != null) b += d.xpBonusPercent;
    }
    if (tools.contains('boots')) b += 10;
    b += weeklyEvent.xpBonusPercent;
    return b;
  }

  int get waterSaveChance {
    var c = 0;
    for (final id in ownedBuildings) {
      final def = BuildingData.tryById(id);
      if (def != null) c += def.waterSaveChance;
    }
    return c.clamp(0, 60);
  }

  double get speedFactor {
    var f = 1.0;
    if (tools.contains('axe')) f *= 0.88;
    if (tools.contains('bucket')) f *= 0.80;
    f *= (1.0 - _buildingGrowBonus);
    var weatherMul = weather.growMultiplier;
    if (tools.contains('hat') && weatherMul > 1.0) {
      weatherMul = 1.0 + (weatherMul - 1.0) * 0.4;
    }
    f *= weatherMul;
    f *= weeklyEvent.growMultiplier;
    return f.clamp(0.35, 1.45);
  }

  int get yieldMultiplier => tools.contains('pickaxe') ? 2 : 1;

  int get petBonusPercent {
    var total = 0;
    for (final a in ShopData.petAnimals) {
      total += (animals[a.id] ?? 0) * a.petBonusPercent;
    }
    return total > 100 ? 100 : total;
  }

  int ownedProduct(String id) => products[id] ?? 0;

  int ownedSeeds(String id) => seeds[id] ?? 0;
  int storedCrop(String id) => harvestedCrops[id] ?? 0;
  int get totalStoredCrops => harvestedCrops.values.fold<int>(0, (total, qty) => total + qty);
  int get totalSeedCount => seeds.values.fold<int>(0, (total, qty) => total + qty);
  int get totalAnimalCount => animals.values.fold<int>(0, (total, qty) => total + qty);
  int ownedAnimals(String id) => animals[id] ?? 0;
  int boostedCycles(String id) => _boostedCycles[id] ?? 0;
  bool hasTool(String id) => tools.contains(id);

  /// سعر السوق يتغير مرة يومياً بصورة ثابتة لكل لاعب/محصول، حتى لا يتبدل مع إعادة بناء الواجهة.
  /// النطاق 85%-120% من السعر الأساسي ويعاد حسابه تلقائياً عند تغير اليوم.
  int marketPricePercent(Crop crop, {DateTime? date}) {
    final day = date ?? baghdadNow;
    final dayKey = day.year * 10000 + day.month * 100 + day.day;
    var seed = dayKey;
    for (var i = 0; i < crop.id.length; i++) {
      seed = (seed * 31 + crop.id.codeUnitAt(i) * (i + 1)) & 0x7fffffff;
    }
    return 90 + (seed % 13); // 90%-102%
  }

  /// سعر القطعة النهائي بعد تقلب السوق ومكافآت الحيوانات الأليفة.
  /// المعول يزيد كمية الحصاد، لا سعر القطعة.
  bool get hasActiveInsurance =>
      insuranceUntil != null && insuranceUntil!.isAfter(DateTime.now());

  int get _weatherMarketBonus {
    final b = weather.marketBonus;
    if (b < 0 && hasActiveInsurance) return (b / 2).round();
    return b;
  }

  /// صافي المبلغ بعد ضريبة المبيعات.
  int applySalesTax(int gross) {
    if (gross <= 0) return 0;
    final tax = (gross * salesTaxPercent / 100).floor();
    return (gross - tax).clamp(0, maxMoney);
  }

  int salesTaxOn(int gross) {
    if (gross <= 0) return 0;
    return (gross * salesTaxPercent / 100).floor();
  }

  /// رسوم تشغيل كنسبة من إجمالي البيع (+ تكلفة توسع المزرعة).
  /// التأمين يخفض الرسوم فقط، لا يلغي الضريبة.
  int maintenanceFeeForSale(int gross, int qty) {
    var rate = 0.03; // 3%
    // توسع المزرعة يزيد الضغط الاقتصادي تدريجياً
    if (plots.length >= 14) rate += 0.008;
    if (plots.length >= 18) rate += 0.007;
    if (totalAnimalCount >= 6) rate += 0.005;
    if (rate > 0.045) rate = 0.045;
    if (hasActiveInsurance) rate *= 0.55;
    final fee = (gross * rate).floor() + (qty * 3);
    return fee.clamp(15, gross);
  }

  int marketSalePrice(Crop crop, {DateTime? date}) {
    final marketBase = (crop.sellPrice * marketPricePercent(crop, date: date) / 100).round();
    var totalBonus = petBonusPercent + buildingSellBonus + season.sellBonus + _weatherMarketBonus;
    if (weeklyEvent.featuredCropId == crop.id) totalBonus += 4;
    totalBonus = totalBonus.clamp(-30, 15);
    return (marketBase * (100 + totalBonus) / 100).round().clamp(1, maxMoney);
  }

  int productSalePrice(String productId) {
    for (final r in BuildingData.recipes) {
      if (r.outputId == productId) {
        final bonus = (buildingSellBonus + season.sellBonus + _weatherMarketBonus).clamp(-25, 20);
        return (r.outputSellPrice * (100 + bonus) / 100).round().clamp(1, maxMoney);
      }
    }
    return 0;
  }

  // ---------- الماء ----------
  /// يشتري عبوات ماء: عشر وحدات لكل عبوة مقابل 3,000 دينار.
  Future<String?> buyWater({int packs = 1}) async {
    if (packs < 1 || packs > 999) return 'اختر عدد عبوات بين 1 و999';
    final units = waterPackSize * packs;
    final cost = waterPackPrice * packs;
    if (money < cost) return 'رصيدك غير كافٍ لشراء الماء';
    if (waterUnits > maxWater - units) return 'مخزون الماء ممتلئ';
    money -= cost;
    waterUnits += units;
    _record('شراء ماء للزراعة', '$units وحدة ماء', moneyDelta: -cost);
    _commit();
    return null;
  }

  /// يسقي مساحة واحدة مرة خلال دورة المحصول ويقلل وقت النمو المتبقي بنسبة 25%.
  Future<String?> waterPlot(int index) async {
    if (index < 0 || index >= plots.length) return 'مساحة الزراعة غير موجودة';
    final plot = plots[index];
    if (plot.isEmpty) return 'ازرع بذرة أولاً قبل السقي';
    if (plot.isReady(DateTime.now())) return 'المحصول ناضج بالفعل؛ احصده أولاً';
    if (plot.watered) return 'تم سقي هذا المحصول بالفعل';
    if (waterUnits < 1) return 'ما عندك ماء كافي؛ اشترِ عبوة ماء من المزرعة';
    final plantedAt = plot.plantedAt;
    if (plantedAt == null || plot.growSeconds < 1) return 'بيانات نمو المحصول غير صالحة';
    final savedSeconds = (plot.growSeconds * 0.25).round();
    if (savedSeconds < 1) return 'هذا المحصول لا يحتاج إلى سقي إضافي';
    plot.plantedAt = plantedAt.subtract(Duration(seconds: savedSeconds));
    plot.watered = true;
    final saveRoll = DateTime.now().millisecondsSinceEpoch % 100;
    final savedWater = waterSaveChance > 0 && saveRoll < waterSaveChance;
    if (!savedWater) waterUnits--;
    _trackProgress('watered');
    final crop = ShopData.tryCropById(plot.cropId!);
    _record(
      'سقي محصول',
      '${crop?.name ?? 'محصول'}: تقليل 25%${savedWater ? ' (البئر وفّر الماء)' : ''}',
    );
    _commit();
    return null;
  }

  // ---------- توسعة المزرعة ----------
  bool get canExpandFarm => plots.length < maxPlotCount;

  int get nextPlotPrice => 90000 + ((plots.length - startingPlotCount).clamp(0, maxPlotCount).toInt() * 110000);

  int get nextPlotRequiredLevel => 4 + ((plots.length - startingPlotCount + 1) * 4);

  /// يفتح مساحة زراعة إضافية مع حفظها ضمن تقدم اللاعب.
  Future<String?> unlockPlot() async {
    if (!canExpandFarm) return 'وصلت للحد الأقصى لمساحات المزرعة';
    if (level < nextPlotRequiredLevel) {
      return 'تحتاج المستوى $nextPlotRequiredLevel لفتح مساحة جديدة';
    }
    final price = nextPlotPrice;
    if (money < price) return 'رصيدك غير كافٍ لفتح مساحة جديدة';
    money -= price;
    plots = [...plots, Plot()];
    _record('توسعة المزرعة', 'فتح مساحة زراعة ${plots.length}', moneyDelta: -price);
    _commit();
    return null;
  }

  // ---------- الشراء ----------
  /// يرجع null عند النجاح، أو رسالة الخطأ.
  Future<String?> buySeed(Crop crop, int qty) async {
    if (qty < 1 || qty > maxSeedBuyPerAction) return 'اختر كمية بين 1 و$maxSeedBuyPerAction';
    final item = ShopData.tryCropById(crop.id);
    if (item == null) return 'هذا المحصول غير موجود في المتجر';
    if (level < item.requiredLevel) return 'يتطلب المستوى ${item.requiredLevel}';
    final total = item.price * qty;
    if (money < total) return 'رصيدك غير كافٍ 💸';
    if (ownedSeeds(item.id) > maxItemStack - qty) return 'مخزون هذه البذور ممتلئ';
    money -= total;
    seeds[item.id] = ownedSeeds(item.id) + qty;
    _record('شراء بذور', '$qty × ${item.name}', moneyDelta: -total);
    _commit();
    return null;
  }

  /// يبيع البذور الفائضة بسعر استرداد واضح (60% من سعر الشراء).
  Future<String?> sellSeed(Crop crop, int qty) async {
    if (qty < 1 || qty > 9999) return 'اختر كمية بين 1 و9999';
    final item = ShopData.tryCropById(crop.id);
    if (item == null) return 'هذا المحصول غير موجود في المتجر';
    final owned = ownedSeeds(item.id);
    if (owned < qty) return 'ما عندك كمية كافية للبيع';
    final unitPrice = (item.price * 0.6).floor();
    if (unitPrice < 1) return 'لا يمكن بيع هذا العنصر حالياً';
    final remaining = owned - qty;
    if (remaining == 0) {
      seeds.remove(item.id);
    } else {
      seeds[item.id] = remaining;
    }
    final credited = _creditMoney(unitPrice * qty);
    _record('بيع بذور', '$qty × ${item.name}', moneyDelta: credited);
    _commit();
    return null;
  }

  Future<String?> buyAnimal(Animal animal) async {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || item.price < 1 || item.cycleSeconds < 1) {
      return 'بيانات الحيوان غير صالحة';
    }
    if (money < item.price) return 'رصيدك غير كافٍ 💸';
    // نسوّي إنتاج القطيع الحالي قبل إضافة حيوان جديد حتى لا يربح عن وقت قبل شرائه.
    if (item.isProductive && ownedAnimals(item.id) > 0) {
      collectAnimal(item);
    }
    money -= item.price;
    if (ownedAnimals(item.id) == 0 && item.isProductive) {
      _lastCollect[item.id] = DateTime.now();
    }
    animals[item.id] = ownedAnimals(item.id) + 1;
    _record('شراء حيوان', item.name, moneyDelta: -item.price);
    _commit();
    return null;
  }

  /// يبيع حيواناً واحداً مقابل 50% من سعر الشراء.
  Future<String?> sellAnimal(Animal animal, {int qty = 1}) async {
    if (qty < 1 || qty > 99) return 'اختر كمية بين 1 و99';
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null) return 'هذا الحيوان غير موجود في المتجر';
    final owned = ownedAnimals(item.id);
    if (owned < qty) return 'ما عندك عدد كافي للبيع';
    final refund = (item.price * 0.5).floor() * qty;
    if (refund < 1) return 'لا يمكن بيع هذا الحيوان حالياً';
    if (item.isProductive) collectAnimal(item);
    animals[item.id] = owned - qty;
    if (animals[item.id] == 0) {
      animals.remove(item.id);
      _lastCollect.remove(item.id);
      _boostedCycles.remove(item.id);
    }
    final credited = _creditMoney(refund);
    _record('بيع حيوان', '$qty × ${item.name}', moneyDelta: credited);
    _commit();
    return null;
  }

  /// شراء علف عام للحيوانات الإنتاجية. كل كيس يحتوي خمس وحدات.
  Future<String?> buyAnimalFeed({int packs = 1}) async {
    if (packs < 1 || packs > 999) return 'اختر عدد أكياس بين 1 و999';
    final cost = animalFeedPackPrice * packs;
    if (money < cost) return 'رصيدك غير كافٍ لشراء العلف';
    if (animalFeed > maxFeed - animalFeedPackSize * packs) return 'مخزون العلف ممتلئ';
    money -= cost;
    animalFeed += animalFeedPackSize * packs;
    _record('شراء علف الحيوانات', '$packs كيس (${animalFeedPackSize * packs} وحدات)', moneyDelta: -cost);
    _commit();
    return null;
  }

  /// إطعام القطيع من نوع واحد: يحتاج وحدة علف لكل حيوان ويعزز الدخل 50% لثلاث دورات.
  Future<String?> feedAnimal(Animal animal) async {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || !item.isProductive) return 'هذا الحيوان لا يحتاج إلى علف الإنتاج';
    final owned = ownedAnimals(item.id);
    if (owned < 1) return 'اشترِ هذا الحيوان أولاً';
    if (animalFeed < owned) return 'العلف غير كافٍ؛ تحتاج $owned وحدة لإطعام القطيع';
    // نجمع الإنتاج الحالي قبل الإطعام حتى لا ينطبق التعزيز بأثر رجعي.
    collectAnimal(item);
    _lastCollect[item.id] = DateTime.now();
    animalFeed -= owned;
    _boostedCycles[item.id] = ((_boostedCycles[item.id] ?? 0) + 3).clamp(0, 30).toInt();
    _record('إطعام الحيوانات', '${item.name}: $owned حيوان، تعزيز 50% لثلاث دورات');
    _commit();
    return null;
  }

  Future<String?> buyTool(ToolItem tool) async {
    final item = ShopData.tryToolById(tool.id);
    if (item == null || item.goldPrice < 1) return 'بيانات الأداة غير صالحة';
    if (tools.contains(item.id)) return 'تملك هذه الأداة بالفعل';
    if (gold < item.goldPrice) return 'عملاتك الذهبية غير كافية 🪙';
    gold -= item.goldPrice;
    tools.add(item.id);
    _record('شراء أداة', item.name, goldDelta: -item.goldPrice);
    _commit();
    return null;
  }

  // ---------- المباني والتصنيع ----------
  Future<String?> buyBuilding(BuildingDef building) async {
    final item = BuildingData.tryById(building.id);
    if (item == null) return 'المبنى غير موجود';
    if (ownedBuildings.contains(item.id)) return 'تملك هذا المبنى بالفعل';
    if (level < item.requiredLevel) return 'يتطلب المستوى ${item.requiredLevel}';
    if (money < item.price) return 'رصيدك غير كافٍ لشراء المبنى';
    money -= item.price;
    ownedBuildings.add(item.id);
    _trackProgress('buildingsBought');
    // lifetime buildings count is owned count for achievements that use target on buildingsBought
    lifetimeStats['buildingsBought'] = ownedBuildings.length;
    _record('شراء مبنى', '${item.emoji} ${item.name}', moneyDelta: -item.price);
    _commit();
    return null;
  }

  Future<String?> buyDecor(DecorItem decor) async {
    final item = DecorData.tryById(decor.id);
    if (item == null) return 'الديكور غير موجود';
    if (ownedDecor.contains(item.id)) return 'تملك هذا الديكور بالفعل';
    if (level < item.requiredLevel) return 'يتطلب المستوى ${item.requiredLevel}';
    if (money < item.price) return 'رصيدك غير كافٍ';
    money -= item.price;
    ownedDecor.add(item.id);
    _trackProgress('decorBought');
    lifetimeStats['decorBought'] = ownedDecor.length;
    _record('شراء ديكور', '${item.emoji} ${item.name}', moneyDelta: -item.price);
    _commit();
    return null;
  }

  Future<String?> buyInsurance() async {
    if (hasActiveInsurance) return 'تأمينك ساري حتى ${insuranceUntil!.toIso8601String().substring(0, 10)}';
    if (money < insurancePrice) return 'رصيدك غير كافٍ لشراء التأمين';
    money -= insurancePrice;
    insuranceUntil = DateTime.now().add(const Duration(days: insuranceDays));
    _record('تأمين المزرعة', 'تغطية $insuranceDays أيام', moneyDelta: -insurancePrice);
    _commit();
    return null;
  }

  bool get canClaimLucky => lastLuckyDate != _dateKey(baghdadNow);

  /// صندوق الحظ اليومي — مكافأة عشوائية مرة باليوم.
  Future<String?> claimLuckyChest() async {
    if (!canClaimLucky) return 'استلمت صندوق الحظ اليوم بالفعل';
    final now = DateTime.now();
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    luckyStreak = lastLuckyDate == yesterday ? luckyStreak + 1 : 1;
    lastLuckyDate = _dateKey(now);
    _trackProgress('luckyOpens');
    final roll = now.millisecondsSinceEpoch % 100;
    String msg;
    if (roll < 8) {
      final g = _creditGold(1 + (luckyStreak ~/ 7));
      msg = 'صندوق ذهبي! +$g ذهب 🪙';
    } else if (roll < 35) {
      final c = _creditMoney(400 + level * 25 + luckyStreak * 20);
      msg = 'كيس فلوس! +$c دينار 💵';
    } else if (roll < 55) {
      waterUnits = (waterUnits + 2).clamp(0, maxWater);
      msg = 'عبوات ماء! +2 ماء 💧';
    } else if (roll < 70) {
      animalFeed = (animalFeed + 1).clamp(0, maxFeed);
      msg = 'علف مجاني! +1 علف 🌽';
    } else {
      final c = _creditMoney(200 + level * 15);
      msg = 'حظ عادي +$c دينار';
    }
    _record('صندوق الحظ', msg);
    _commit();
    return msg;
  }

  void _refreshCrafts() {
    final now = DateTime.now();
    final done = <int>[];
    for (var i = 0; i < activeCrafts.length; i++) {
      final c = activeCrafts[i];
      final readyAt = DateTime.tryParse(c['readyAt']?.toString() ?? '');
      if (readyAt != null && !now.isBefore(readyAt)) {
        final outId = c['outputId']?.toString() ?? '';
        final qty = (c['qty'] is num) ? (c['qty'] as num).toInt() : 1;
        if (outId.isNotEmpty) {
          products[outId] = (ownedProduct(outId) + qty).clamp(0, maxProducts);
          _trackProgress('crafted', qty);
        }
        done.add(i);
      }
    }
    for (final i in done.reversed) {
      final c = activeCrafts.removeAt(i);
      _record('انتهى التصنيع', '${c['name'] ?? 'منتج'}');
    }
    if (done.isNotEmpty) _commit();
  }

  Future<String?> startCraft(RecipeDef recipe, {int qty = 1}) async {
    _refreshCrafts();
    if (qty < 1 || qty > 20) return 'اختر كمية بين 1 و20';
    final item = BuildingData.tryRecipe(recipe.id);
    if (item == null) return 'الوصفة غير موجودة';
    if (!hasBuilding(item.buildingId)) return 'تحتاج مبنى "${BuildingData.tryById(item.buildingId)?.name ?? item.buildingId}" أولاً';
    if (level < item.requiredLevel) return 'يتطلب المستوى ${item.requiredLevel}';
    final need = item.inputQty * qty;
    if (storedCrop(item.inputCropId) < need) return 'المحاصيل غير كافية للتصنيع';
    final left = storedCrop(item.inputCropId) - need;
    if (left <= 0) {
      harvestedCrops.remove(item.inputCropId);
    } else {
      harvestedCrops[item.inputCropId] = left;
    }
    final ready = DateTime.now().add(Duration(seconds: item.craftSeconds * qty));
    activeCrafts.add({
      'id': item.id,
      'name': item.name,
      'emoji': item.emoji,
      'outputId': item.outputId,
      'outputName': item.outputName,
      'qty': qty,
      'readyAt': ready.toIso8601String(),
    });
    _record('بدء تصنيع', '${item.emoji} ${item.name} ×$qty');
    _commit();
    return null;
  }

  Future<String?> sellProduct(String productId, int qty) async {
    if (_economyBusy) return 'عملية مالية قيد التنفيذ، حاول بعد لحظة';
    _refreshCrafts();
    if (qty < 1 || qty > maxSellPerAction) return 'اختر كمية بين 1 و$maxSellPerAction';
    final owned = ownedProduct(productId);
    if (owned < qty) return 'الكمية غير كافية';
    final unit = productSalePrice(productId);
    if (unit < 1) return 'منتج غير معروف';
    final gross = unit * qty;
    final tax = salesTaxOn(gross);
    final fee = maintenanceFeeForSale(gross, qty);
    final afterTax = applySalesTax(gross);
    final net = (afterTax - fee).clamp(0, maxMoney);
    if (net < 1) return 'بعد الضريبة والرسوم لا يتبقى ربح';
    _economyBusy = true;
    try {
      final left = owned - qty;
      if (left <= 0) {
        products.remove(productId);
      } else {
        products[productId] = left;
      }
      final credited = _creditMoney(net);
      _trackProgress('sold', qty);
      _record('بيع منتج مصنّع', '$productId ×$qty (ضريبة $tax + تشغيل $fee)', moneyDelta: credited);
      _commit();
      return null;
    } finally {
      _economyBusy = false;
    }
  }

  /// مكافأة العودة بعد غياب (مرة عند التحميل).
  void tickWorld() {
    _refreshCrafts();
    lastActiveAt = DateTime.now();
    _commit();
  }

  void applyOfflineRewardIfNeeded() {
    final last = lastActiveAt;
    if (last == null) {
      lastActiveAt = DateTime.now();
      return;
    }
    final hours = DateTime.now().difference(last).inHours;
    if (hours < 2) {
      lastActiveAt = DateTime.now();
      return;
    }
    final capped = hours.clamp(4, 10);
    final cash = (level * 25 * capped).clamp(0, 8000);
    final credited = _creditMoney(cash);
    lastOfflineRewardMessage = 'مرحباً بعودتك! حصلت على $credited دينار عن $capped ساعة غياب';
    lastActiveAt = DateTime.now();
    _record('مكافأة العودة', lastOfflineRewardMessage!, moneyDelta: credited);
    _commit();
  }

  // ---------- المزرعة ----------
  Future<bool> plant(int index, Crop crop) async {
    if (index < 0 || index >= plots.length) return false;
    final item = ShopData.tryCropById(crop.id);
    if (item == null || level < item.requiredLevel) return false;
    final plot = plots[index];
    if (!plot.isEmpty || ownedSeeds(item.id) < 1) return false;
    final left = ownedSeeds(item.id) - 1;
    if (left == 0) {
      seeds.remove(item.id);
    } else {
      seeds[item.id] = left;
    }
    plot.cropId = item.id;
    plot.plantedAt = DateTime.now();
    plot.watered = false;
    final seconds = (item.growSeconds * speedFactor).ceil();
    plot.growSeconds = seconds < 3 ? 3 : seconds;
    _trackProgress('planted');
    _commit();
    return true;
  }

  /// يحصد مساحة واحدة. يرجع null إذا لم يحصد شيئاً؛
  /// وإذا كان السبب مخزن ممتلئ تجد الرسالة في [lastHarvestError].
  Future<HarvestResult?> harvest(int index) async => _harvestPlots([index]);

  /// يحصد كل المحاصيل الناضجة دفعة واحدة ويحدّث الحالة مرة واحدة.
  Future<HarvestResult?> harvestAllReady() async => _harvestPlots(List<int>.generate(plots.length, (i) => i));

  HarvestResult? _harvestPlots(Iterable<int> indexes) {
    lastHarvestError = null;
    final now = DateTime.now();
    var totalXp = 0;
    var harvestedCount = 0;
    var cleanedInvalidPlot = false;
    String? fullCropName;

    for (final i in indexes) {
      if (i < 0 || i >= plots.length) continue;
      final plot = plots[i];
      if (plot.isEmpty || !plot.isReady(now)) continue;
      final crop = ShopData.tryCropById(plot.cropId!);
      if (crop == null) {
        plot.clear();
        cleanedInvalidPlot = true;
        continue;
      }
      final availableSpace = maxItemStack - storedCrop(crop.id);
      if (availableSpace <= 0) {
        fullCropName ??= crop.name;
        continue;
      }
      final harvested = yieldMultiplier.clamp(1, availableSpace).toInt();
      harvestedCrops[crop.id] = storedCrop(crop.id) + harvested;
      _trackProgress('harvested', harvested);
      _record('حصاد محصول', '${crop.emoji} ${crop.name} ×$harvested');
      final xpGain = (crop.xpReward * (100 + buildingXpBonus + season.xpBonus) / 100).round();
      totalXp += xpGain;
      harvestedCount += harvested;
      plot.clear();
    }

    if (harvestedCount == 0) {
      if (fullCropName != null) lastHarvestError = 'مخزن $fullCropName ممتلئ، بع جزءاً منه أولاً';
      if (cleanedInvalidPlot) _commit();
      return null;
    }
    final levelsGained = _grantXp(totalXp);
    _commit();
    return HarvestResult(income: 0, xp: totalXp, levelsGained: levelsGained, harvestedCount: harvestedCount);
  }

  int _addXp(int amount) {
    if (amount <= 0) return 0;
    xp = (xp + amount).clamp(0, maxStat).toInt();
    var gained = 0;
    // حلقة محمية بحد أقصى إذا احتوى حفظ تالف على XP ضخم.
    while (xp >= xpNeeded && gained < 10000) {
      xp -= xpNeeded;
      if (level >= maxLevel) {
        xp = 0;
        break;
      }
      level++;
      _creditGold(levelUpGoldReward);
      gained++;
    }
    return gained;
  }

  // ---------- بيع المحاصيل ----------
  /// يبيع المحاصيل المخزونة بسعر السوق الحالي مع احتساب مكافآت الحيوانات الأليفة.
  Future<String?> sellHarvestedCrop(Crop crop, int qty) async {
    if (_economyBusy) return 'عملية مالية قيد التنفيذ، حاول بعد لحظة';
    if (qty < 1 || qty > maxSellPerAction) return 'اختر كمية بين 1 و$maxSellPerAction';
    final item = ShopData.tryCropById(crop.id);
    if (item == null) return 'هذا المحصول غير موجود في السوق';
    final owned = storedCrop(item.id);
    if (owned < qty) return 'الكمية المخزونة غير كافية';
    final gross = marketSalePrice(item) * qty;
    if (gross < 1) return 'تعذر حساب سعر البيع';
    final tax = salesTaxOn(gross);
    final fee = maintenanceFeeForSale(gross, qty);
    final afterTax = applySalesTax(gross);
    final net = (afterTax - fee).clamp(0, maxMoney);
    if (net < 1) return 'بعد الضريبة ورسوم التشغيل لا يتبقى ربح من هذه الكمية';
    if (net > maxMoney - money) return 'رصيدك قريب من الحد الأقصى؛ اصرف جزءاً من الرصيد قبل البيع';
    _economyBusy = true;
    try {
      final left = owned - qty;
      if (left <= 0) {
        harvestedCrops.remove(item.id);
      } else {
        harvestedCrops[item.id] = left;
      }
      _trackProgress('sold', qty);
      final credited = _creditMoney(net);
      _record(
        'بيع محاصيل مخزونة',
        '${item.emoji} ${item.name} ×$qty (ضريبة $tax + تشغيل $fee)',
        moneyDelta: credited,
      );
      _commit();
      return null;
    } finally {
      _economyBusy = false;
    }
  }

  Future<String?> sellAllHarvestedCrops() async {
    if (_economyBusy) return 'عملية مالية قيد التنفيذ، حاول بعد لحظة';
    if (totalStoredCrops == 0) return 'ما عندك محاصيل مخزونة للبيع';
    var totalGross = 0;
    var totalQty = 0;
    final sold = <String, int>{};
    for (final crop in ShopData.crops) {
      final qty = storedCrop(crop.id);
      if (qty <= 0) continue;
      totalGross += marketSalePrice(crop) * qty;
      totalQty += qty;
      sold[crop.id] = qty;
    }
    if (sold.isEmpty) return 'ما عندك محاصيل صالحة للبيع';
    final tax = salesTaxOn(totalGross);
    final fee = maintenanceFeeForSale(totalGross, totalQty);
    final afterTax = applySalesTax(totalGross);
    final net = (afterTax - fee).clamp(0, maxMoney);
    if (net < 1) return 'بعد الضريبة ورسوم التشغيل لا يتبقى ربح';
    if (net > maxMoney - money) return 'قيمة المحاصيل تتجاوز المساحة المتبقية في رصيدك؛ بع المحاصيل على دفعات';
    _economyBusy = true;
    try {
      for (final id in sold.keys) {
        harvestedCrops.remove(id);
      }
      _trackProgress('sold', totalQty);
      final credited = _creditMoney(net);
      _record('بيع كل المحاصيل المخزونة', '$totalQty محصول (ضريبة $tax + تشغيل $fee)', moneyDelta: credited);
      _commit();
      return null;
    } finally {
      _economyBusy = false;
    }
  }

  // ---------- الحيوانات ----------
  int pendingCycles(Animal animal, DateTime now) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || !item.isProductive || item.cycleSeconds < 1 || ownedAnimals(item.id) == 0) {
      return 0;
    }
    final last = _lastCollect[item.id] ?? now;
    final elapsedSeconds = now.difference(last).inSeconds;
    if (elapsedSeconds <= 0) return 0;
    final cycles = elapsedSeconds ~/ item.cycleSeconds;
    return cycles > maxStoredCycles ? maxStoredCycles : cycles;
  }

  /// دخل عدد معين من الدورات مع احتساب الدورات المعززة (+50%).
  int _animalIncome(Animal item, int cycles) {
    if (cycles <= 0) return 0;
    final count = ownedAnimals(item.id);
    final boosted = cycles.clamp(0, boostedCycles(item.id)).toInt();
    final normal = cycles - boosted;
    final base = normal * item.incomePerCycle * count;
    final cycleBonus = (boosted * item.incomePerCycle * count * 1.5).round();
    final raw = base + cycleBonus;
    return (raw * (100 + buildingAnimalBonus) / 100).round();
  }

  /// يقدّم وقت آخر تحصيل ويستهلك الدورات المعززة بعد التحصيل.
  void _advanceCollect(Animal item, int cycles, DateTime now) {
    final boosted = cycles.clamp(0, boostedCycles(item.id)).toInt();
    final last = _lastCollect[item.id] ?? now;
    _lastCollect[item.id] = cycles >= maxStoredCycles ? now : last.add(Duration(seconds: cycles * item.cycleSeconds));
    if (boosted > 0) {
      final left = boostedCycles(item.id) - boosted;
      if (left > 0) {
        _boostedCycles[item.id] = left;
      } else {
        _boostedCycles.remove(item.id);
      }
    }
  }

  int pendingIncome(Animal animal, DateTime now) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null) return 0;
    return _animalIncome(item, pendingCycles(item, now));
  }

  /// إجمالي الإنتاج الجاهز لكل الحيوانات الإنتاجية.
  int get totalPendingAnimalIncome {
    final now = DateTime.now();
    return ShopData.productiveAnimals.fold<int>(
      0,
      (total, animal) => total + pendingIncome(animal, now),
    );
  }

  /// يجمع إنتاج الحيوانات دفعة واحدة مع تسجيل كل نوع في سجل المعاملات.
  Future<int> collectAllAnimals() async {
    final now = DateTime.now();
    var total = 0;
    var processedAny = false;
    for (final animal in ShopData.productiveAnimals) {
      final cycles = pendingCycles(animal, now);
      if (cycles == 0) continue;
      processedAny = true;
      final remaining = (maxMoney - money - total).clamp(0, maxMoney).toInt();
      final credited = _animalIncome(animal, cycles).clamp(0, remaining).toInt();
      total += credited;
      _record('تحصيل إنتاج الحيوانات', animal.name, moneyDelta: credited);
      _advanceCollect(animal, cycles, now);
    }
    if (total > 0) money += total;
    if (processedAny) {
      _trackProgress('animalCollections');
      _commit();
    }
    return total;
  }

  Future<int> collectAnimal(Animal animal) async {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || !item.isProductive) return 0;
    final now = DateTime.now();
    final cycles = pendingCycles(item, now);
    if (cycles == 0) return 0;
    final income = _creditMoney(_animalIncome(item, cycles));
    _record('تحصيل إنتاج الحيوانات', item.name, moneyDelta: income);
    _advanceCollect(item, cycles, now);
    _trackProgress('animalCollections');
    _commit();
    return income;
  }

  // ---------- الحفظ المحلي أولاً ثم مزامنة Firestore ----------
  String? uid;
  Timer? _cloudTimer;
  bool _cloudWriteAllowed = false;
  String? loadError;
  String? cloudSyncError;
  bool isCloudSaving = false;
  DateTime? lastCloudSync;
  Future<void> _saveQueue = Future<void>.value();
  Future<void> _cloudSaveQueue = Future<void>.value();

  /// يمنع الحفظ أثناء تبديل الحساب أو قبل استعادة نسخة قابلة للاستخدام.
  bool _persistBlocked = false;

  /// يلغي نتائج تحميل قديمة إذا بدأ تحميل أحدث (تبديل حساب سريع).
  int _loadToken = 0;
  bool _disposed = false;

  String get _localKey => uid == null ? _saveKey : '${_saveKey}_$uid';
  String get _cloudBaselineKey => 'farm_party_cloud_baseline_${uid ?? "local"}';
  String get _offlineBackupKey => '${_localKey}_offline_backup';

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> setPlayerName(String name) async {
    final cleaned = _cleanName(name);
    if (cleaned.isEmpty || cleaned == playerName) return;
    playerName = cleaned;
    _commit();
  }

  static String _cleanName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
  }

  void _commit() {
    _stateUpdatedAt = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    _save();
  }

  Map<String, dynamic> _toMap() {
    final map = <String, dynamic>{
      'name': playerName,
      'money': money,
      'gold': gold,
      'xp': xp,
      'level': level,
      'seeds': Map<String, int>.from(seeds),
      'harvestedCrops': Map<String, int>.from(harvestedCrops),
      'animals': Map<String, int>.from(animals),
      'animalFeed': animalFeed,
      'waterUnits': waterUnits,
      'boostedCycles': Map<String, int>.from(_boostedCycles),
      'tools': tools.toList(),
      'buildings': ownedBuildings.toList(),
      'decor': ownedDecor.toList(),
      'products': Map<String, int>.from(products),
      'activeCrafts': activeCrafts.map((e) => Map<String, dynamic>.from(e)).toList(),
      'transactions': transactions.map((e) => Map<String, dynamic>.from(e)).toList(),
      'dailyStreak': dailyStreak,
      'luckyStreak': luckyStreak,
      'dailyProgress': Map<String, int>.from(dailyProgress),
      'claimedDailyMissions': claimedDailyMissions.toList(),
      'lifetimeStats': Map<String, int>.from(lifetimeStats),
      'claimedAchievements': claimedAchievements.toList(),
      'collect': _lastCollect.map((k, v) => MapEntry(k, v.toIso8601String())),
      'plots': plots
          .map((p) => {
                'crop': p.cropId,
                'at': p.plantedAt?.toIso8601String(),
                'sec': p.growSeconds,
                'watered': p.watered,
              })
          .toList(),
      'updated': _stateUpdatedAt,
    };
    // لا نكتب null إلى Firestore (يكسر القواعد أحياناً)
    if (lastDailyRewardDate != null) map['lastDailyRewardDate'] = lastDailyRewardDate;
    if (lastLuckyDate != null) map['lastLuckyDate'] = lastLuckyDate;
    if (dailyProgressDate != null) map['dailyProgressDate'] = dailyProgressDate;
    if (lastActiveAt != null) map['lastActiveAt'] = lastActiveAt!.toIso8601String();
    if (insuranceUntil != null) map['insuranceUntil'] = insuranceUntil!.toIso8601String();
    map['legacyUnverified'] = legacyUnverified;
    if (legacyImportedAt != null) map['legacyImportedAt'] = legacyImportedAt;
    if (lastOfflineRewardMessage != null) map['lastOfflineRewardMessage'] = lastOfflineRewardMessage;
    return map;
  }

  void _resetToDefaults() {
    playerName = 'المزارع';
    _stateUpdatedAt = DateTime.now().millisecondsSinceEpoch;
    money = 18000;
    gold = 12;
    xp = 0;
    level = 1;
    seeds.clear();
    harvestedCrops.clear();
    animals.clear();
    animalFeed = 0;
    waterUnits = 4;
    _boostedCycles.clear();
    tools.clear();
    ownedBuildings.clear();
    ownedDecor.clear();
    products.clear();
    activeCrafts.clear();
    transactions.clear();
    lastDailyRewardDate = null;
    dailyStreak = 0;
    lastLuckyDate = null;
    luckyStreak = 0;
    insuranceUntil = null;
    _economyBusy = false;
    dailyProgressDate = _dateKey(baghdadNow);
    dailyProgress.clear();
    claimedDailyMissions.clear();
    lifetimeStats.clear();
    claimedAchievements.clear();
    _lastCollect.clear();
    lastHarvestError = null;
    lastActiveAt = DateTime.now();
    lastOfflineRewardMessage = null;
    legacyUnverified = false;
    legacyImportedAt = null;
    plots = List.generate(startingPlotCount, (_) => Plot());
  }

  // ---- قراءة آمنة من الخريطة المحفوظة ----
  static int _int(Object? v, int def, int min, int max) => (v is num ? v.toInt() : def).clamp(min, max).toInt();

  static Set<String> _strSet(Object? v) => v is List ? v.map((e) => e.toString()).toSet() : <String>{};

  static Map<String, int> _intMap(Object? v, int max, {bool Function(String key)? keep}) {
    final out = <String, int>{};
    if (v is Map) {
      for (final e in v.entries) {
        final key = e.key.toString();
        if (e.value is num && (keep == null || keep(key))) {
          final qty = (e.value as num).toInt().clamp(0, max).toInt();
          if (qty > 0) out[key] = qty;
        }
      }
    }
    return out;
  }

  void _applyMap(Map<String, dynamic> m) {
    if (m['updated'] is num) _stateUpdatedAt = (m['updated'] as num).toInt();
    final savedName = m['name'];
    if (savedName is String) {
      final cleaned = _cleanName(savedName);
      if (cleaned.isNotEmpty) playerName = cleaned;
    }

    money = _int(m['money'], money, 0, maxMoney);
    gold = _int(m['gold'], gold, 0, maxGold);
    xp = _int(m['xp'], xp, 0, maxStat);
    level = _int(m['level'], level, 1, maxLevel);

    seeds
      ..clear()
      ..addAll(_intMap(m['seeds'], maxStat));
    harvestedCrops
      ..clear()
      ..addAll(_intMap(m['harvestedCrops'], maxItemStack, keep: (id) => ShopData.tryCropById(id) != null));
    animals
      ..clear()
      ..addAll(_intMap(m['animals'], maxStat));

    animalFeed = _int(m['animalFeed'], 0, 0, maxFeed);
    // الحفظ القديم يحصل على كمية ماء بسيطة للميزة الجديدة.
    waterUnits = _int(m['waterUnits'], 5, 0, maxWater);

    _boostedCycles
      ..clear()
      ..addAll(_intMap(m['boostedCycles'], 30, keep: (id) {
        final a = ShopData.tryAnimalById(id);
        return a != null && a.isProductive;
      }));

    tools
      ..clear()
      ..addAll(_strSet(m['tools']));

    ownedBuildings
      ..clear()
      ..addAll(_strSet(m['buildings']).where((id) => BuildingData.tryById(id) != null));

    ownedDecor
      ..clear()
      ..addAll(_strSet(m['decor']).where((id) => DecorData.tryById(id) != null));

    lastLuckyDate = m['lastLuckyDate'] is String ? m['lastLuckyDate'] as String : null;
    luckyStreak = _int(m['luckyStreak'], 0, 0, 9999);
    final ins = m['insuranceUntil'];
    insuranceUntil = ins is String ? DateTime.tryParse(ins) : null;

    products
      ..clear()
      ..addAll(_intMap(m['products'], maxProducts));

    activeCrafts.clear();
    final savedCrafts = m['activeCrafts'];
    if (savedCrafts is List) {
      for (final entry in savedCrafts.whereType<Map>().take(30)) {
        try {
          activeCrafts.add(Map<String, dynamic>.from(entry));
        } catch (_) {}
      }
    }

    final la = m['lastActiveAt'];
    if (la is String) lastActiveAt = DateTime.tryParse(la);
    // بوابة المراجعة القديمة كانت مخصصة للاقتصاد الذي تديره Cloud Functions.
    // في نمط اللعب المحلي لا نوقف مكافآت اللاعب بسبب هذا العلم القديم.
    legacyUnverified = false;
    legacyImportedAt = m['legacyImportedAt'] is String ? m['legacyImportedAt'] as String : null;
    lastOfflineRewardMessage = m['lastOfflineRewardMessage'] is String
        ? (m['lastOfflineRewardMessage'] as String).substring(0, (m['lastOfflineRewardMessage'] as String).length.clamp(0, 200).toInt())
        : null;

    transactions.clear();
    final savedTransactions = m['transactions'];
    if (savedTransactions is List) {
      for (final entry in savedTransactions.whereType<Map>().take(60)) {
        try {
          transactions.add(Map<String, dynamic>.from(entry));
        } catch (_) {
          // تجاهل معاملة تالفة دون خسارة بقية الحفظ.
        }
      }
    }

    lastDailyRewardDate = m['lastDailyRewardDate'] is String ? m['lastDailyRewardDate'] as String : null;
    dailyStreak = _int(m['dailyStreak'], 0, 0, 7);
    dailyProgressDate = m['dailyProgressDate'] is String ? m['dailyProgressDate'] as String : _dateKey(baghdadNow);
    dailyProgress
      ..clear()
      ..addAll(_intMap(m['dailyProgress'], maxStat));
    claimedDailyMissions
      ..clear()
      ..addAll(_strSet(m['claimedDailyMissions']));
    lifetimeStats
      ..clear()
      ..addAll(_intMap(m['lifetimeStats'], maxStat));
    claimedAchievements
      ..clear()
      ..addAll(_strSet(m['claimedAchievements']));
    _ensureDailyProgressDate();

    _lastCollect.clear();
    final savedCollect = m['collect'];
    if (savedCollect is Map) {
      for (final entry in savedCollect.entries) {
        final parsed = DateTime.tryParse(entry.value?.toString() ?? '');
        if (parsed != null) _lastCollect[entry.key.toString()] = parsed;
      }
    }
    // حيوان إنتاجي بدون وقت تحصيل (حفظ قديم/تالف) كان ما ينتج أبداً.
    final nowTs = DateTime.now();
    for (final entry in animals.entries) {
      final a = ShopData.tryAnimalById(entry.key);
      if (a != null && a.isProductive && entry.value > 0) {
        _lastCollect.putIfAbsent(a.id, () => nowTs);
      }
    }

    final savedPlots = m['plots'];
    // نبقي توافق الحفظ القديم مع استعادة التوسعات حتى الحد الأقصى.
    final restoredCount =
        savedPlots is List ? savedPlots.length.clamp(startingPlotCount, maxPlotCount).toInt() : startingPlotCount;
    plots = List.generate(restoredCount, (_) => Plot());
    if (savedPlots is List) {
      for (var i = 0; i < plots.length && i < savedPlots.length; i++) {
        final rawPlot = savedPlots[i];
        if (rawPlot is! Map) continue;
        final crop = rawPlot['crop'];
        final at = DateTime.tryParse(rawPlot['at']?.toString() ?? '');
        if (crop is String && ShopData.tryCropById(crop) != null && at != null) {
          plots[i].cropId = crop;
          plots[i].plantedAt = at;
          plots[i].growSeconds = _int(rawPlot['sec'], 0, 3, 100000000);
          plots[i].watered = rawPlot['watered'] == true;
        }
      }
    }
  }

  /// يسمح للاختبارات أو لإغلاق التطبيق بانتظار اكتمال آخر حفظ محلي.
  Future<void> waitForLocalSave() => _saveQueue;

  Future<void> _save() {
    if (_persistBlocked) return _saveQueue;
    // نسلسل الكتابات: عمليتان سريعتان ما يجوز أن تنتهي الأقدم أخيراً.
    final key = _localKey;
    final snapshot = jsonEncode(_toMap());
    _saveQueue = _saveQueue.catchError((_) {}).then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, snapshot);
      } catch (_) {
        // هذا الملف نسخة استرجاع فقط؛ لا نمنع مزامنة Firebase إذا فشل التخزين المحلي.
      }
      _scheduleCloudSave();
    });
    return _saveQueue;
  }

  void _scheduleCloudSave() {
    if (uid == null || _persistBlocked || _disposed || !_cloudWriteAllowed) return;
    _cloudTimer?.cancel();
    _cloudTimer = Timer(const Duration(seconds: 2), _pushCloud);
  }

  String _friendlyCloudError(Object error, {bool loading = false}) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return error.message?.isNotEmpty == true
              ? error.message!
              : 'رفض Firestore الوصول. تأكد من نشر firestore.rules على مشروع Firebase الصحيح ومن تأكيد البريد الإلكتروني.';
        case 'unauthenticated':
          return 'انتهت جلسة تسجيل الدخول. سجّل الدخول من جديد.';
        case 'unavailable':
        case 'network-request-failed':
          return 'لا يمكن الوصول إلى Firebase حالياً. تحقق من الإنترنت ثم أعد المحاولة.';
        case 'deadline-exceeded':
          return 'استغرقت مزامنة Firebase وقتاً طويلاً. تحقق من الاتصال وأعد المحاولة.';
        default:
          return '${loading ? 'تعذر تحميل' : 'تعذر حفظ'} بيانات Firebase (${error.code}).';
      }
    }
    return loading
        ? 'تعذر تحميل بيانات الحساب من Firebase. تحقق من الاتصال ثم أعد المحاولة.'
        : 'تعذر حفظ البيانات في Firebase. سيظهر التنبيه هنا حتى تنجح المزامنة.';
  }

  Future<void> _pushCloud() {
    final id = uid;
    if (id == null || _persistBlocked || _disposed || !_cloudWriteAllowed) return Future<void>.value();

    // نسلسل الكتابات حتى لا تستبدل لقطة قديمة لقطة أحدث.
    _cloudSaveQueue = _cloudSaveQueue.catchError((_) {}).then((_) async {
      if (uid != id || _persistBlocked || _disposed || !_cloudWriteAllowed) return;
      isCloudSaving = true;
      cloudSyncError = null;
      notifyListeners();
      try {
        final save = _toMap();
        final updated = (save['updated'] as num).toInt();
        final publicProfile = <String, dynamic>{
          'uid': id,
          'name': playerName,
          'updated': updated,
        };
        final farmSnapshot = <String, dynamic>{
          'uid': id,
          'name': playerName,
          'plots': plots.map((plot) => {
                'cropId': plot.cropId,
                'plantedAt': plot.plantedAt?.toIso8601String(),
                'growSeconds': plot.growSeconds,
                'watered': plot.watered,
              }).toList(growable: false),
          'updated': updated,
        };

        final db = FirebaseFirestore.instance;
        final batch = db.batch();
        batch.set(db.collection('users').doc(id), save);
        batch.set(db.collection('publicProfiles').doc(id), publicProfile);
        batch.set(db.collection('farmSnapshots').doc(id), farmSnapshot);
        await batch.commit();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_cloudBaselineKey, true);
        lastCloudSync = DateTime.now();
        cloudSyncError = null;
      } catch (error) {
        cloudSyncError = _friendlyCloudError(error);
      } finally {
        isCloudSaving = false;
        notifyListeners();
      }
    });
    return _cloudSaveQueue;
  }

  /// يجدد هوية Firebase قبل عمليات Firestore، لأن القواعد تشترط email_verified
  /// وقد تبقى مطالبة البريد القديمة داخل ID token حتى بعد تأكيد البريد.
  Future<void> _refreshVerifiedFirebaseIdentity(String expectedUid) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != expectedUid) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unauthenticated',
        message: 'لا توجد جلسة Firebase صالحة لهذا الحساب.',
      );
    }

    await user.reload();
    user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != expectedUid) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unauthenticated',
        message: 'انتهت جلسة تسجيل الدخول.',
      );
    }

    await user.getIdToken(true);
    final token = await user.getIdTokenResult();
    if (token.claims?['email_verified'] != true) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'يجب تأكيد البريد الإلكتروني ثم تسجيل الدخول من جديد.',
      );
    }
  }

  /// يعيد التحقق من Firestore قبل أول رفع بعد جلسة لعب بدأت دون إنترنت.
  /// يستخدم users/{uid} بوصفه مستند الحفظ المعتمد في وضع Local First؛
  /// لا يعتمد على gameStates الذي كان خاصاً بنظام Cloud Functions السابق.
  Future<void> _verifyCloudBaseline() async {
    final id = uid;
    if (id == null || _disposed) return;

    try {
      await _refreshVerifiedFirebaseIdentity(id);
      final prefs = await SharedPreferences.getInstance();
      final baseline = prefs.getBool(_cloudBaselineKey) ?? false;
      final local = _toMap();
      final db = FirebaseFirestore.instance;
      Map<String, dynamic>? remote;

      final cloudSnapshot = await db.collection('users').doc(id)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      if (cloudSnapshot.exists && cloudSnapshot.data() != null) {
        remote = Map<String, dynamic>.from(cloudSnapshot.data()!);
      }

      final localUpdated = (local['updated'] as num).toInt();
      final remoteUpdated = remote != null && remote['updated'] is num
          ? (remote['updated'] as num).toInt() : 0;
      if (remote != null && (!baseline || remoteUpdated >= localUpdated)) {
        if (!baseline && localUpdated > remoteUpdated) {
          await prefs.setString(_offlineBackupKey, jsonEncode(local));
        }
        _applyMap(remote);
      }

      _cloudWriteAllowed = true;
      await prefs.setBool(_cloudBaselineKey, true);
      lastCloudSync = remote != null ? DateTime.now() : null;
      cloudSyncError = null;
      loadError = null;
      _refreshCrafts();
      notifyListeners();
      await _save();
    } catch (error) {
      _cloudWriteAllowed = false;
      cloudSyncError = _friendlyCloudError(error, loading: true);
      notifyListeners();
    }
  }

  /// يرفع البيانات فوراً (قبل تسجيل الخروج أو عند إيقاف التطبيق).
  Future<void> flushSave() async {
    _cloudTimer?.cancel();
    // فرض حفظ محلي فوري قبل السحابة
    if (!_persistBlocked && !_disposed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_localKey, jsonEncode(_toMap()));
      } catch (_) {}
    }
    await _saveQueue.catchError((_) {});
    if (!_cloudWriteAllowed) await _verifyCloudBaseline();
    if (_cloudWriteAllowed) {
      _cloudTimer?.cancel();
      await _save();
      await _saveQueue.catchError((_) {});
      await _pushCloud();
    }
  }

  /// يبدأ من الحفظ المحلي حتى لا تتوقف اللعبة عند انقطاع الإنترنت، ثم يطابقه مع Firestore.
  /// إذا لم يسبق تأكيد نسخة سحابية لهذا الجهاز، تُفضّل النسخة السحابية عند وجود تعارض
  /// ويُحتفظ بنسخة محلية احتياطية بدلاً من الكتابة فوق بيانات الحساب دون تحقق.
  Future<bool> loadForUser(String userId) async {
    final token = ++_loadToken;
    _cloudTimer?.cancel();
    _persistBlocked = true;
    _cloudWriteAllowed = false;
    uid = userId;
    loadError = null;
    cloudSyncError = null;
    isCloudSaving = false;
    lastCloudSync = null;
    _resetToDefaults();
    notifyListeners();

    Map<String, dynamic>? local;
    bool baseline = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      baseline = prefs.getBool(_cloudBaselineKey) ?? false;
      final accountRaw = prefs.getString('${_saveKey}_$userId');
      final legacyRaw = prefs.getString(_saveKey);
      final raw = accountRaw ?? legacyRaw;
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) local = Map<String, dynamic>.from(decoded);
      }
      if (token != _loadToken) return false;
      if (local != null) _applyMap(local);
    } catch (error) {
      debugPrint('Local farm save could not be read: $error');
      if (token != _loadToken) return false;
    }

    // The local farm is now usable. A cloud outage must not block gameplay.
    _persistBlocked = false;
    notifyListeners();

    Map<String, dynamic>? remote;
    try {
      // جدّد ID token حتى تصل مطالبة email_verified المحدثة إلى Firestore.
      await _refreshVerifiedFirebaseIdentity(userId);
      final db = FirebaseFirestore.instance;
      final cloudSnapshot = await db.collection('users').doc(userId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      if (cloudSnapshot.exists && cloudSnapshot.data() != null) {
        remote = Map<String, dynamic>.from(cloudSnapshot.data()!);
      }
      if (token != _loadToken) return false;

      final localUpdated = local != null && local['updated'] is num
          ? (local['updated'] as num).toInt() : 0;
      final remoteUpdated = remote != null && remote['updated'] is num
          ? (remote['updated'] as num).toInt() : 0;
      final preferRemote = remote != null &&
          (!baseline || local == null || remoteUpdated >= localUpdated);

      if (preferRemote) {
        // Preserve an unverified offline-only save before selecting the known cloud copy.
        if (!baseline && local != null && localUpdated > remoteUpdated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_offlineBackupKey, jsonEncode(local));
        }
        _applyMap(remote);
      } else if (local != null) {
        _applyMap(local);
      } else {
        _resetToDefaults();
        final authName = FirebaseAuth.instance.currentUser?.displayName?.trim();
        if (authName != null && authName.isNotEmpty) playerName = _cleanName(authName);
      }

      _cloudWriteAllowed = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cloudBaselineKey, true);
      lastCloudSync = remote != null ? DateTime.now() : null;
      cloudSyncError = null;
      loadError = null;

      _refreshCrafts();
      applyOfflineRewardIfNeeded();
      notifyListeners();

      // Save locally immediately; the cloud write is debounced and never blocks an action.
      await _save();
      if (token != _loadToken) return false;
      if (remote == null || (local != null && localUpdated > remoteUpdated)) {
        _cloudTimer?.cancel();
        await _pushCloud();
      }
      return token == _loadToken;
    } catch (error) {
      if (token != _loadToken) return false;
      _persistBlocked = false;
      _cloudWriteAllowed = false;
      loadError = null;
      cloudSyncError = _friendlyCloudError(error, loading: true);
      _refreshCrafts();
      applyOfflineRewardIfNeeded();
      notifyListeners();
      await _save(); // local only; never upload until a server read succeeds.
      return true;
    }
  }

  /// تفريغ الحالة عند تسجيل الخروج.
  void reset() {
    _loadToken++;
    _cloudTimer?.cancel();
    uid = null;
    _persistBlocked = false;
    _cloudWriteAllowed = false;
    loadError = null;
    cloudSyncError = null;
    isCloudSaving = false;
    lastCloudSync = null;
    _resetToDefaults();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cloudTimer?.cancel();
    super.dispose();
  }
}
