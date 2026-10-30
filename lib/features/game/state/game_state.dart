import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_functions/cloud_functions.dart';
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
  bool legacyUnverified = false;
  int _lastServerRevision = 0;
  final Stopwatch _serverClock = Stopwatch();
  DateTime? _serverClockAnchor;

  DateTime get serverNow => _serverClockAnchor == null
      ? DateTime.now()
      : _serverClockAnchor!.add(_serverClock.elapsed);

  // Iraq uses UTC+3; derive calendar features from Baghdad time, not device timezone.
  DateTime get baghdadNow => serverNow.toUtc().add(const Duration(hours: 3));

  void _syncServerClock(Object? rawServerTime) {
    if (rawServerTime is! String) return;
    final parsed = DateTime.tryParse(rawServerTime)?.toLocal();
    if (parsed == null) return;
    if (_serverClockAnchor != null && !parsed.isAfter(serverNow)) return;
    _serverClock.stop();
    _serverClock.reset();
    _serverClockAnchor = parsed;
    _serverClock.start();
  }
  final Map<String, String> _pendingActionIds = {};

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
  bool get canClaimDailyReward => lastDailyRewardDate != _dateKey(serverNow);

  String _dateKey(DateTime date) {
    final baghdad = date.toUtc().add(const Duration(hours: 3));
    return '${baghdad.year.toString().padLeft(4, '0')}-${baghdad.month.toString().padLeft(2, '0')}-${baghdad.day.toString().padLeft(2, '0')}';
  }

  // ---------- المكافأة اليومية ----------
  Future<String?> claimDailyReward() => _runSecureErrorAction('claimDailyReward');

  // ---------- المهام اليومية والإنجازات ----------
  void _ensureDailyProgressDate() {
    final today = _dateKey(serverNow);
    if (dailyProgressDate == today) return;
    dailyProgressDate = today;
    dailyProgress.clear();
    claimedDailyMissions.clear();
  }

  int dailyMissionProgress(Map<String, dynamic> mission) {
    if (dailyProgressDate != _dateKey(serverNow)) return 0;
    return dailyProgress[mission['stat'] as String] ?? 0;
  }

  bool isDailyMissionClaimed(String id) =>
      dailyProgressDate == _dateKey(serverNow) && claimedDailyMissions.contains(id);

  bool canClaimDailyMission(Map<String, dynamic> mission) =>
      !isDailyMissionClaimed(mission['id'] as String) &&
      dailyMissionProgress(mission) >= (mission['target'] as int);

  static Map<String, dynamic>? _findDefinition(List<Map<String, dynamic>> list, String id) {
    for (final item in list) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  Future<String?> claimDailyMission(String id) => _runSecureErrorAction('claimDailyMission', {'id': id});

  int achievementProgress(Map<String, dynamic> achievement) {
    if (achievement['stat'] == 'level') return level;
    return lifetimeStats[achievement['stat'] as String] ?? 0;
  }

  bool isAchievementClaimed(String id) => claimedAchievements.contains(id);

  bool canClaimAchievement(Map<String, dynamic> achievement) =>
      !claimedAchievements.contains(achievement['id'] as String) &&
      achievementProgress(achievement) >= (achievement['target'] as int);

  Future<String?> claimAchievement(String id) => _runSecureErrorAction('claimAchievement', {'id': id});

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
      insuranceUntil != null && insuranceUntil!.isAfter(serverNow);

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
  Future<String?> buyWater({int packs = 1}) => _runSecureErrorAction('buyWater', {'packs': packs});

  /// يسقي مساحة واحدة مرة خلال دورة المحصول ويقلل وقت النمو المتبقي بنسبة 25%.
  Future<String?> waterPlot(int index) => _runSecureErrorAction('waterPlot', {'index': index});

  // ---------- توسعة المزرعة ----------
  bool get canExpandFarm => plots.length < maxPlotCount;

  int get nextPlotPrice => 90000 + ((plots.length - startingPlotCount).clamp(0, maxPlotCount).toInt() * 110000);

  int get nextPlotRequiredLevel => 4 + ((plots.length - startingPlotCount + 1) * 4);

  /// يفتح مساحة زراعة إضافية مع حفظها ضمن تقدم اللاعب.
  Future<String?> unlockPlot() => _runSecureErrorAction('unlockPlot');

  // ---------- الشراء ----------
  /// يرجع null عند النجاح، أو رسالة الخطأ.
  Future<String?> buySeed(Crop crop, int qty) => _runSecureErrorAction('buySeed', {'id': crop.id, 'qty': qty});

  /// يبيع البذور الفائضة بسعر استرداد واضح (60% من سعر الشراء).
  Future<String?> sellSeed(Crop crop, int qty) => _runSecureErrorAction('sellSeed', {'id': crop.id, 'qty': qty});

  Future<String?> buyAnimal(Animal animal) => _runSecureErrorAction('buyAnimal', {'id': animal.id});

  /// يبيع حيواناً واحداً مقابل 50% من سعر الشراء.
  Future<String?> sellAnimal(Animal animal, {int qty = 1}) => _runSecureErrorAction('sellAnimal', {'id': animal.id, 'qty': qty});

  /// شراء علف عام للحيوانات الإنتاجية. كل كيس يحتوي خمس وحدات.
  Future<String?> buyAnimalFeed({int packs = 1}) => _runSecureErrorAction('buyAnimalFeed', {'packs': packs});

  /// إطعام القطيع من نوع واحد: يحتاج وحدة علف لكل حيوان ويعزز الدخل 50% لثلاث دورات.
  Future<String?> feedAnimal(Animal animal) => _runSecureErrorAction('feedAnimal', {'id': animal.id});

  Future<String?> buyTool(ToolItem tool) => _runSecureErrorAction('buyTool', {'id': tool.id});

  // ---------- المباني والتصنيع ----------
  Future<String?> buyBuilding(BuildingDef building) => _runSecureErrorAction('buyBuilding', {'id': building.id});

  Future<String?> buyDecor(DecorItem decor) => _runSecureErrorAction('buyDecor', {'id': decor.id});

  Future<String?> buyInsurance() => _runSecureErrorAction('buyInsurance');

  bool get canClaimLucky => lastLuckyDate != _dateKey(serverNow);

  /// صندوق الحظ اليومي — مكافأة عشوائية مرة باليوم.
  Future<String?> claimLuckyChest() async {
    try {
      final payload = await _callSecureAction('claimLuckyChest');
      final result = payload['result'];
      if (result is Map && result['data'] is Map) return (result['data'] as Map)['message']?.toString() ?? 'تم فتح الصندوق';
      return 'تم فتح الصندوق';
    } catch (error) {
      return _friendlyCallableError(error);
    }
  }

  Future<String?> startCraft(RecipeDef recipe, {int qty = 1}) => _runSecureErrorAction('startCraft', {'id': recipe.id, 'qty': qty});

  Future<String?> sellProduct(String productId, int qty) => _runSecureErrorAction('sellProduct', {'id': productId, 'qty': qty});

  /// مكافأة العودة بعد غياب (مرة عند التحميل).
  void tickWorld() {
    unawaited(_callSecureAction('refresh').then<void>((_) {}).catchError((_) {}));
  }

  Future<void> applyOfflineRewardIfNeeded() async {
    try { await _callSecureAction('refresh'); } catch (_) {}
  }

  // ---------- المزرعة ----------
  Future<bool> plant(int index, Crop crop) async {
    try { await _callSecureAction('plant', {'index': index, 'id': crop.id}); return true; }
    catch (_) { return false; }
  }

  /// يحصد مساحة واحدة. يرجع null إذا لم يحصد شيئاً؛
  /// وإذا كان السبب مخزن ممتلئ تجد الرسالة في [lastHarvestError].
  Future<HarvestResult?> harvest(int index) async {
    try {
      final payload = await _callSecureAction('harvest', {'index': index});
      final result = payload['result']; final data = result is Map ? result['data'] : null;
      if (data is! Map) return null;
      return HarvestResult(income: 0, xp: (data['xp'] as num?)?.toInt() ?? 0, levelsGained: (data['levelsGained'] as num?)?.toInt() ?? 0, harvestedCount: (data['harvestedCount'] as num?)?.toInt() ?? 0);
    } catch (_) { return null; }
  }
  /// يحصد كل المحاصيل الناضجة دفعة واحدة ويحدّث الحالة مرة واحدة.
  Future<HarvestResult?> harvestAllReady() async {
    try {
      final payload = await _callSecureAction('harvest', {'all': true});
      final result = payload['result']; final data = result is Map ? result['data'] : null;
      if (data is! Map) return null;
      return HarvestResult(income: 0, xp: (data['xp'] as num?)?.toInt() ?? 0, levelsGained: (data['levelsGained'] as num?)?.toInt() ?? 0, harvestedCount: (data['harvestedCount'] as num?)?.toInt() ?? 0);
    } catch (error) { lastHarvestError = _friendlyCallableError(error); return null; }
  }
  // ---------- بيع المحاصيل ----------
  /// يبيع المحاصيل المخزونة بسعر السوق الحالي مع احتساب مكافآت الحيوانات الأليفة.
  Future<String?> sellHarvestedCrop(Crop crop, int qty) => _runSecureErrorAction('sellCrop', {'id': crop.id, 'qty': qty});

  Future<String?> sellAllHarvestedCrops() => _runSecureErrorAction('sellAllCrops');

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
  int pendingIncome(Animal animal, DateTime now) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null) return 0;
    return _animalIncome(item, pendingCycles(item, now));
  }

  /// إجمالي الإنتاج الجاهز لكل الحيوانات الإنتاجية.
  int get totalPendingAnimalIncome {
    final now = serverNow;
    return ShopData.productiveAnimals.fold<int>(
      0,
      (total, animal) => total + pendingIncome(animal, now),
    );
  }

  /// يجمع إنتاج الحيوانات دفعة واحدة مع تسجيل كل نوع في سجل المعاملات.
  Future<int> collectAllAnimals() async {
    try { final payload = await _callSecureAction('collectAllAnimals'); final r = payload['result']; final d = r is Map ? r['data'] : null; return d is Map ? (d['credited'] as num?)?.toInt() ?? 0 : 0; } catch (_) { return 0; }
  }

  Future<int> collectAnimal(Animal animal) async {
    try { final payload = await _callSecureAction('collectAnimal', {'id': animal.id}); final r = payload['result']; final d = r is Map ? r['data'] : null; return d is Map ? (d['credited'] as num?)?.toInt() ?? 0 : 0; } catch (_) { return 0; }
  }

  // ---------- الحفظ والمزامنة (Firestore هو المصدر الأساسي) ----------
  String? uid;
  String? loadError;
  String? cloudSyncError;
  bool isCloudSaving = false;
  DateTime? lastCloudSync;
  Future<void> _saveQueue = Future<void>.value();

  /// يمنع أي حفظ (محلي أو سحابي) إذا فشل جلب بيانات اللاعب،
  /// حتى لا تُكتب القيم الافتراضية فوق التقدم الحقيقي.
  bool _persistBlocked = false;

  /// يلغي نتائج تحميل قديمة إذا بدأ تحميل أحدث (تبديل حساب سريع).
  int _loadToken = 0;
  bool _disposed = false;

  String get _localKey => uid == null ? _saveKey : '${_saveKey}_$uid';

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> setPlayerName(String name) async {
    final cleaned = _cleanName(name);
    if (cleaned.isEmpty || cleaned == playerName) return;
    await _callSecureAction('rename', {'name': cleaned});
  }

  static String _cleanName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
  }

  Map<String, dynamic> _toMap() {
    final map = <String, dynamic>{
      'name': playerName,
      'revision': _lastServerRevision,
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
      'updated': DateTime.now().millisecondsSinceEpoch,
    };
    // لا نكتب null إلى Firestore (يكسر القواعد أحياناً)
    if (lastDailyRewardDate != null) map['lastDailyRewardDate'] = lastDailyRewardDate;
    if (lastLuckyDate != null) map['lastLuckyDate'] = lastLuckyDate;
    if (dailyProgressDate != null) map['dailyProgressDate'] = dailyProgressDate;
    if (lastActiveAt != null) map['lastActiveAt'] = lastActiveAt!.toIso8601String();
    if (legacyUnverified) map['legacyUnverified'] = true;
    if (lastOfflineRewardMessage != null) map['lastOfflineRewardMessage'] = lastOfflineRewardMessage;
    if (insuranceUntil != null) map['insuranceUntil'] = insuranceUntil!.toIso8601String();
    return map;
  }

  void _resetToDefaults() {
    playerName = 'المزارع';
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
    dailyProgressDate = _dateKey(serverNow);
    dailyProgress.clear();
    claimedDailyMissions.clear();
    lifetimeStats.clear();
    claimedAchievements.clear();
    _lastCollect.clear();
    lastHarvestError = null;
    lastActiveAt = serverNow;
    lastOfflineRewardMessage = null;
    legacyUnverified = false;
    _lastServerRevision = 0;
    _serverClock.stop();
    _serverClock.reset();
    _serverClockAnchor = null;
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
    legacyUnverified = m['legacyUnverified'] == true;
    _lastServerRevision = _int(m['revision'], _lastServerRevision, 0, 1000000000);
    lastOfflineRewardMessage = m['lastOfflineRewardMessage'] is String ? m['lastOfflineRewardMessage'] as String : null;

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
    dailyProgressDate = m['dailyProgressDate'] is String ? m['dailyProgressDate'] as String : _dateKey(serverNow);
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
    final nowTs = serverNow;
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
      // Cloud state is server-authoritative and is written only by callable Functions.
    });
    return _saveQueue;
  }

  Future<Map<String, dynamic>> _callSecureAction(String action, [Map<String, dynamic> args = const {}]) async {
    if (uid == null) throw StateError('يجب تسجيل الدخول لتنفيذ العملية.');
    final requestKey = '$action:${jsonEncode(args)}';
    final requestId = _pendingActionIds.putIfAbsent(requestKey, () {
      final random = math.Random.secure();
      return '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32)}';
    });
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('applyGameAction');
    try {
      final response = await callable.call(<String, dynamic>{
        'action': action,
        'args': args,
        'requestId': requestId,
      });
      final payload = Map<String, dynamic>.from(response.data as Map);
      _syncServerClock(payload['serverTime']);
      final rawState = payload['state'];
      if (rawState is! Map) throw StateError('استجابة الخادم لا تحتوي على حالة لعبة صحيحة.');
      final incomingState = Map<String, dynamic>.from(rawState);
      final incomingRevision = _int(incomingState['revision'], 0, 0, 1000000000);
      if (incomingRevision >= _lastServerRevision) {
        _applyMap(incomingState);
        _lastServerRevision = incomingRevision;
      }
      legacyUnverified = payload['legacyUnverified'] == true || rawState['legacyUnverified'] == true;
      final result = payload['result'];
      if (result is Map && result['data'] is Map) {
        final data = Map<String, dynamic>.from(result['data'] as Map);
        if (data['offlineReward'] is String) lastOfflineRewardMessage = data['offlineReward'] as String;
      }
      lastCloudSync = DateTime.now();
      cloudSyncError = null;
      _pendingActionIds.remove(requestKey);
      notifyListeners();
      await _writeLocalCacheOnly();
      return payload;
    } catch (error) {
      cloudSyncError = _friendlyCallableError(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _writeLocalCacheOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, jsonEncode(_toMap()));
    } catch (_) {
      // Local storage is a disposable cache; Firebase remains authoritative.
    }
  }

  String _friendlyCallableError(Object error) {
    if (error is FirebaseFunctionsException) {
      if (error.code == 'unauthenticated') return 'انتهت جلسة الدخول. سجّل الدخول من جديد.';
      if (error.code == 'permission-denied') return error.message ?? 'يجب تأكيد البريد الإلكتروني وتفعيل App Check.';
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') return 'الخادم غير متاح حالياً. تحقق من الإنترنت وحاول مرة أخرى.';
      return error.message ?? 'رفض الخادم العملية (${error.code}).';
    }
    if (error is StateError) return error.message;
    return 'تعذر تنفيذ العملية على الخادم. تحقق من الاتصال وحاول مرة أخرى.';
  }

  Future<String?> _runSecureErrorAction(String action, [Map<String, dynamic> args = const {}]) async {
    try {
      await _callSecureAction(action, args);
      return null;
    } catch (error) {
      return _friendlyCallableError(error);
    }
  }

  /// يحفظ نسخة كاش محلية فقط قبل إغلاق التطبيق؛ لا يكتب الحالة إلى Firebase.
  /// كل تغيير مؤثر يكون قد عاد من الخادم قبل أن تعرضه الواجهة كنجاح.
  Future<void> flushSave() async {
    if (!_persistBlocked && !_disposed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_localKey, jsonEncode(_toMap()));
      } catch (_) {}
    }
    await _saveQueue.catchError((_) {});
  }

  /// تحميل الحالة المعتمدة عبر Callable Cloud Function.
  /// الخادم هو المصدر الوحيد للحالة؛ التخزين المحلي نسخة عرض مؤقتة فقط.
  /// لا يُستورد أي حفظ محلي إلى الحساب لأنه قابل للتعديل خارج التطبيق.
  Future<bool> loadForUser(String userId) async {
    final token = ++_loadToken;
    _persistBlocked = true;
    uid = userId;
    loadError = null;
    cloudSyncError = null;
    isCloudSaving = false;
    lastCloudSync = null;
    _resetToDefaults();
    notifyListeners();

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('bootstrapGame');
      final response = await callable.call();
      if (token != _loadToken) return false;
      final payload = Map<String, dynamic>.from(response.data as Map);
      _syncServerClock(payload['serverTime']);
      final rawState = payload['state'];
      if (rawState is! Map) throw StateError('لم يرجع الخادم بيانات حساب صالحة.');
      final incomingState = Map<String, dynamic>.from(rawState);
      _applyMap(incomingState);
      _lastServerRevision = _int(incomingState['revision'], 0, 0, 1000000000);
      legacyUnverified = payload['legacyUnverified'] == true || rawState['legacyUnverified'] == true;
      _persistBlocked = false;
      loadError = null;
      cloudSyncError = null;
      lastCloudSync = DateTime.now();
      final result = payload['result'];
      if (result is Map && result['data'] is Map) {
        final data = Map<String, dynamic>.from(result['data'] as Map);
        if (data['offlineReward'] is String) lastOfflineRewardMessage = data['offlineReward'] as String;
      }
      notifyListeners();
      await _writeLocalCacheOnly();
      return token == _loadToken;
    } catch (error) {
      if (token != _loadToken) return false;
      _persistBlocked = true;
      loadError = _friendlyCallableError(error);
      notifyListeners();
      return false;
    }
  }

  /// تفريغ الحالة عند تسجيل الخروج.
  void reset() {
    _loadToken++;
    uid = null;
    _persistBlocked = false;
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
    _serverClock.stop();
    super.dispose();
  }
}
