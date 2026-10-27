import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shop/data/shop_data.dart';
import '../../shop/models/animal.dart';
import '../../shop/models/crop.dart';
import '../../shop/models/tool_item.dart';
import '../models/plot.dart';

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
  static const int maxStoredCycles = 10;
  static const int levelUpGoldReward = 2;
  static const int startingPlotCount = 12;
  static const int maxPlotCount = 24;
  static const int maxItemStack = 1000000;

  String playerName = 'المزارع';
  int money = 50000; // الدينار العراقي
  int gold = 50; // العملات الذهبية
  int xp = 0;
  int level = 1;

  final Map<String, int> seeds = {};
  /// المحاصيل التي تم حصادها ولم تُبع بعد.
  final Map<String, int> harvestedCrops = {};
  final Map<String, int> animals = {};
  final Set<String> tools = {};
  final Map<String, DateTime> _lastCollect = {};
  int animalFeed = 0;
  int waterUnits = 10;
  static const int waterPackSize = 10;
  static const int waterPackPrice = 3000;
  final Map<String, int> _boostedCycles = {};
  List<Plot> plots = List.generate(startingPlotCount, (_) => Plot());
  final List<Map<String, dynamic>> transactions = [];
  String? lastDailyRewardDate;
  int dailyStreak = 0;

  // تقدم المهام والإنجازات محفوظ محلياً مع ملف اللاعب.
  String? dailyProgressDate;
  final Map<String, int> dailyProgress = {};
  final Set<String> claimedDailyMissions = {};
  final Map<String, int> lifetimeStats = {};
  final Set<String> claimedAchievements = {};

  static const List<Map<String, dynamic>> dailyMissionDefinitions = [
    {'id': 'plant_3', 'title': 'بداية خضراء', 'description': 'ازرع 3 بذور اليوم', 'stat': 'planted', 'target': 3, 'money': 1500, 'xp': 10, 'icon': '🌱'},
    {'id': 'harvest_3', 'title': 'وقت الحصاد', 'description': 'احصد 3 محاصيل اليوم', 'stat': 'harvested', 'target': 3, 'money': 2500, 'xp': 20, 'icon': '🌾'},
    {'id': 'sell_3', 'title': 'تاجر ماهر', 'description': 'بع 3 محاصيل اليوم', 'stat': 'sold', 'target': 3, 'money': 2000, 'xp': 15, 'icon': '🪙'},
    {'id': 'water_2', 'title': 'ساقي المزرعة', 'description': 'اسقِ محصولين اليوم', 'stat': 'watered', 'target': 2, 'money': 1000, 'xp': 10, 'icon': '💧'},
    {'id': 'collect_1', 'title': 'خير الحيوانات', 'description': 'حصّل إنتاج الحيوانات مرة', 'stat': 'animalCollections', 'target': 1, 'money': 2000, 'xp': 15, 'icon': '🐄'},
  ];

  static const List<Map<String, dynamic>> achievementDefinitions = [
    {'id': 'first_plant', 'title': 'أول بذرة', 'description': 'ازرع أول محصول في مزرعتك', 'stat': 'planted', 'target': 1, 'money': 1000, 'gold': 1, 'icon': '🌱'},
    {'id': 'farmer_25', 'title': 'مزارع مجتهد', 'description': 'ازرع 25 بذرة بالمجموع', 'stat': 'planted', 'target': 25, 'money': 5000, 'gold': 2, 'icon': '🚜'},
    {'id': 'harvest_25', 'title': 'خبير الحصاد', 'description': 'احصد 25 محصولاً بالمجموع', 'stat': 'harvested', 'target': 25, 'money': 7000, 'gold': 2, 'icon': '🌾'},
    {'id': 'seller_25', 'title': 'تاجر المزرعة', 'description': 'بع 25 محصولاً بالمجموع', 'stat': 'sold', 'target': 25, 'money': 8000, 'gold': 3, 'icon': '💰'},
    {'id': 'level_5', 'title': 'مزارع متقدم', 'description': 'وصل إلى المستوى الخامس', 'stat': 'level', 'target': 5, 'money': 10000, 'gold': 5, 'icon': '🏆'},
    {'id': 'water_10', 'title': 'صديق الماء', 'description': 'اسقِ 10 محاصيل بالمجموع', 'stat': 'watered', 'target': 10, 'money': 4000, 'gold': 2, 'icon': '💧'},
  ];

  bool get canClaimDailyReward {
    final today = _dateKey(DateTime.now());
    return lastDailyRewardDate != today;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _creditMoney(int requested) {
    if (requested <= 0) return 0;
    final remaining = (2000000000 - money).clamp(0, 2000000000).toInt();
    final credited = requested.clamp(0, remaining).toInt();
    money += credited;
    return credited;
  }

  void _record(String title, String detail, {int moneyDelta = 0, int goldDelta = 0}) {
    transactions.insert(0, {
      'title': title, 'detail': detail, 'money': moneyDelta, 'gold': goldDelta,
      'at': DateTime.now().toIso8601String(),
    });
    if (transactions.length > 60) transactions.removeRange(60, transactions.length);
  }

  String? claimDailyReward() {
    if (!canClaimDailyReward) return 'استلمت مكافأتك اليومية بالفعل';
    final now = DateTime.now();
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    // The 7-day reward track loops; day 7 must not be claimable forever.
    dailyStreak = lastDailyRewardDate == yesterday ? (dailyStreak % 7) + 1 : 1;
    final cashReward = 2000 + (dailyStreak - 1) * 500;
    final goldReward = dailyStreak == 7 ? 2 : 0;
    final creditedCash = _creditMoney(cashReward);
    final remainingGold = (1000000 - gold).clamp(0, 1000000).toInt();
    final creditedGold = goldReward.clamp(0, remainingGold).toInt();
    gold += creditedGold;
    lastDailyRewardDate = _dateKey(now);
    _record('المكافأة اليومية', 'اليوم $dailyStreak من 7', moneyDelta: creditedCash, goldDelta: creditedGold);
    _commit();
    return null;
  }

  void _ensureDailyProgressDate() {
    final today = _dateKey(DateTime.now());
    if (dailyProgressDate == today) return;
    dailyProgressDate = today;
    dailyProgress.clear();
    claimedDailyMissions.clear();
  }

  void _trackProgress(String stat, [int amount = 1]) {
    if (amount <= 0) return;
    _ensureDailyProgressDate();
    dailyProgress[stat] = ((dailyProgress[stat] ?? 0) + amount).clamp(0, 1000000000).toInt();
    lifetimeStats[stat] = ((lifetimeStats[stat] ?? 0) + amount).clamp(0, 1000000000).toInt();
  }

  int dailyMissionProgress(Map<String, dynamic> mission) {
    if (dailyProgressDate != _dateKey(DateTime.now())) return 0;
    return dailyProgress[mission['stat'] as String] ?? 0;
  }

  bool isDailyMissionClaimed(String id) =>
      dailyProgressDate == _dateKey(DateTime.now()) && claimedDailyMissions.contains(id);

  bool canClaimDailyMission(Map<String, dynamic> mission) =>
      !isDailyMissionClaimed(mission['id'] as String) &&
      dailyMissionProgress(mission) >= (mission['target'] as int);

  String? claimDailyMission(String id) {
    _ensureDailyProgressDate();
    Map<String, dynamic>? mission;
    for (final item in dailyMissionDefinitions) {
      if (item['id'] == id) { mission = item; break; }
    }
    if (mission == null) return 'المهمة غير موجودة';
    if (claimedDailyMissions.contains(id)) return 'استلمت مكافأة هذه المهمة اليوم';
    if (dailyMissionProgress(mission) < (mission['target'] as int)) return 'أكمل المهمة أولاً حتى تستلم المكافأة';
    final reward = mission['money'] as int;
    final credited = _creditMoney(reward);
    final gained = _addXp(mission['xp'] as int);
    claimedDailyMissions.add(id);
    _record('مكافأة مهمة يومية', mission['title'] as String, moneyDelta: credited);
    if (gained > 0) _record('ترقية مستوى', 'ارتفع مستواك إلى $level');
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

  String? claimAchievement(String id) {
    Map<String, dynamic>? achievement;
    for (final item in achievementDefinitions) {
      if (item['id'] == id) { achievement = item; break; }
    }
    if (achievement == null) return 'الإنجاز غير موجود';
    if (claimedAchievements.contains(id)) return 'استلمت مكافأة هذا الإنجاز سابقاً';
    if (achievementProgress(achievement) < (achievement['target'] as int)) return 'أكمل شروط الإنجاز أولاً';
    final cash = _creditMoney(achievement['money'] as int);
    final requestedGold = achievement['gold'] as int;
    final creditedGold = requestedGold.clamp(0, (1000000 - gold).clamp(0, 1000000)).toInt();
    gold += creditedGold;
    claimedAchievements.add(id);
    _record('مكافأة إنجاز', achievement['title'] as String, moneyDelta: cash, goldDelta: creditedGold);
    _commit();
    return null;
  }

  // ---------- مشتقات ----------
  int get xpNeeded => level * 100;

  double get speedFactor {
    var f = 1.0;
    if (tools.contains('axe')) f *= 0.75;
    if (tools.contains('bucket')) f *= 0.5;
    return f;
  }

  int get yieldMultiplier => tools.contains('pickaxe') ? 2 : 1;

  int get petBonusPercent {
    var total = 0;
    for (final a in ShopData.petAnimals) {
      total += (animals[a.id] ?? 0) * a.petBonusPercent;
    }
    return total > 100 ? 100 : total;
  }

  int ownedSeeds(String id) => seeds[id] ?? 0;
  int storedCrop(String id) => harvestedCrops[id] ?? 0;
  int get totalStoredCrops => harvestedCrops.values.fold<int>(0, (sum, qty) => sum + qty);
  int get totalSeedCount => seeds.values.fold<int>(0, (sum, qty) => sum + qty);
  int get totalAnimalCount => animals.values.fold<int>(0, (sum, qty) => sum + qty);
  int ownedAnimals(String id) => animals[id] ?? 0;
  int boostedCycles(String id) => _boostedCycles[id] ?? 0;
  static const int animalFeedPackSize = 5;
  static const int animalFeedPackPrice = 15000;
  bool hasTool(String id) => tools.contains(id);

  /// سعر السوق يتغير مرة يومياً بصورة ثابتة لكل لاعب/محصول، حتى لا يتبدل مع إعادة بناء الواجهة.
  /// النطاق 85%-120% من السعر الأساسي ويعاد حسابه تلقائياً عند تغير اليوم.
  int marketPricePercent(Crop crop, {DateTime? date}) {
    final day = date ?? DateTime.now();
    final dayKey = day.year * 10000 + day.month * 100 + day.day;
    var seed = dayKey;
    for (var i = 0; i < crop.id.length; i++) {
      seed = (seed * 31 + crop.id.codeUnitAt(i) * (i + 1)) & 0x7fffffff;
    }
    return 85 + (seed % 36);
  }

  /// سعر القطعة النهائي بعد تقلب السوق ومكافآت الأدوات والحيوانات الأليفة.
  int marketSalePrice(Crop crop, {DateTime? date}) {
    final marketBase = (crop.sellPrice * marketPricePercent(crop, date: date) / 100).round();
    // Pickaxe improves the amount harvested, not the price of each individual crop.
    return (marketBase * (100 + petBonusPercent) / 100).round();
  }

  /// يشتري خزاناً صغيراً من الماء: عشر وحدات مقابل 3,000 دينار.
  String? buyWater({int packs = 1}) {
    if (packs < 1 || packs > 999) return 'اختر عدد عبوات بين 1 و999';
    final units = waterPackSize * packs;
    final cost = waterPackPrice * packs;
    if (money < cost) return 'رصيدك غير كافٍ لشراء الماء';
    if (waterUnits > 1000000 - units) return 'مخزون الماء ممتلئ';
    money -= cost;
    waterUnits += units;
    _record('شراء ماء للزراعة', '$units وحدة ماء', moneyDelta: -cost);
    _commit();
    return null;
  }

  /// يسقي مساحة واحدة مرة خلال دورة المحصول ويقلل وقت النمو المتبقي بنسبة 25%.
  String? waterPlot(int index) {
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
    waterUnits--;
    _trackProgress('watered');
    final crop = ShopData.tryCropById(plot.cropId!);
    _record('سقي محصول', '${crop?.name ?? 'محصول'}: تقليل وقت النمو 25%');
    _commit();
    return null;
  }

  bool get canExpandFarm => plots.length < maxPlotCount;

  int get nextPlotPrice => 25000 + ((plots.length - startingPlotCount).clamp(0, maxPlotCount).toInt() * 25000);

  int get nextPlotRequiredLevel => 1 + ((plots.length - startingPlotCount + 1) * 2);

  /// يفتح مساحة زراعة إضافية مع حفظها ضمن تقدم اللاعب.
  String? unlockPlot() {
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
  String? buySeed(Crop crop, int qty) {
    if (qty < 1 || qty > 9999) return 'اختر كمية بين 1 و9999';
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
  /// يرجع null عند النجاح أو رسالة خطأ عند تعذر البيع.
  String? sellSeed(Crop crop, int qty) {
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

  String? buyAnimal(Animal animal) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || item.price < 1 || item.cycleSeconds < 1) {
      return 'بيانات الحيوان غير صالحة';
    }
    if (money < item.price) return 'رصيدك غير كافٍ 💸';
    // Settle the current herd before adding another animal, so a new purchase
    // cannot earn production for time before it was owned.
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
  String? sellAnimal(Animal animal, {int qty = 1}) {
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
  String? buyAnimalFeed({int packs = 1}) {
    if (packs < 1 || packs > 999) return 'اختر عدد أكياس بين 1 و999';
    final cost = animalFeedPackPrice * packs;
    if (money < cost) return 'رصيدك غير كافٍ لشراء العلف';
    if (animalFeed > 1000000 - animalFeedPackSize * packs) return 'مخزون العلف ممتلئ';
    money -= cost;
    animalFeed += animalFeedPackSize * packs;
    _record('شراء علف الحيوانات', '$packs كيس (${animalFeedPackSize * packs} وحدات)', moneyDelta: -cost);
    _commit();
    return null;
  }

  /// إطعام القطيع من نوع واحد: يحتاج وحدة علف لكل حيوان ويعزز الدخل 50% لثلاث دورات.
  String? feedAnimal(Animal animal) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || !item.isProductive) return 'هذا الحيوان لا يحتاج إلى علف الإنتاج';
    final owned = ownedAnimals(item.id);
    if (owned < 1) return 'اشترِ هذا الحيوان أولاً';
    if (animalFeed < owned) return 'العلف غير كافٍ؛ تحتاج $owned وحدة لإطعام القطيع';
    // Collect existing production before feeding so the boost never applies retroactively.
    collectAnimal(item);
    _lastCollect[item.id] = DateTime.now();
    animalFeed -= owned;
    _boostedCycles[item.id] = ((_boostedCycles[item.id] ?? 0) + 3).clamp(0, 30).toInt();
    _record('إطعام الحيوانات', '${item.name}: $owned حيوان، تعزيز 50% لثلاث دورات');
    _commit();
    return null;
  }

  String? buyTool(ToolItem tool) {
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

  // ---------- المزرعة ----------
  bool plant(int index, Crop crop) {
    if (index < 0 || index >= plots.length) return false;
    final item = ShopData.tryCropById(crop.id);
    if (item == null || level < item.requiredLevel) return false;
    final plot = plots[index];
    if (!plot.isEmpty || ownedSeeds(item.id) < 1) return false;
    seeds[item.id] = ownedSeeds(item.id) - 1;
    plot.cropId = item.id;
    plot.plantedAt = DateTime.now();
    plot.watered = false;
    final seconds = (item.growSeconds * speedFactor).ceil();
    plot.growSeconds = seconds < 3 ? 3 : seconds;
    _trackProgress('planted');
    _commit();
    return true;
  }

  HarvestResult? harvest(int index) {
    if (index < 0 || index >= plots.length) return null;
    final plot = plots[index];
    if (plot.isEmpty || !plot.isReady(DateTime.now())) return null;
    final crop = ShopData.tryCropById(plot.cropId!);
    if (crop == null) {
      plot.clear();
      _commit();
      return null;
    }
    final availableSpace = maxItemStack - storedCrop(crop.id);
    if (availableSpace <= 0) return null;
    final harvested = yieldMultiplier.clamp(1, availableSpace).toInt();
    harvestedCrops[crop.id] = storedCrop(crop.id) + harvested;
    _trackProgress('harvested', harvested);
    _record('حصاد محصول', '${crop.emoji} ${crop.name} ×$harvested');
    plot.clear();
    final gained = _addXp(crop.xpReward);
    _commit();
    return HarvestResult(income: 0, xp: crop.xpReward, levelsGained: gained, harvestedCount: harvested);
  }

  /// يحصد كل المحاصيل الناضجة دفعة واحدة ويحدّث الحالة مرة واحدة.
  HarvestResult? harvestAllReady() {
    final now = DateTime.now();
    var totalXp = 0;
    var harvestedCount = 0;
    var cleanedInvalidPlot = false;

    for (final plot in plots) {
      if (plot.isEmpty || !plot.isReady(now)) continue;
      final crop = ShopData.tryCropById(plot.cropId!);
      if (crop == null) {
        plot.clear();
        cleanedInvalidPlot = true;
        continue;
      }
      final availableSpace = maxItemStack - storedCrop(crop.id);
      if (availableSpace <= 0) continue;
      final harvested = yieldMultiplier.clamp(1, availableSpace).toInt();
      harvestedCrops[crop.id] = storedCrop(crop.id) + harvested;
      _trackProgress('harvested', harvested);
      totalXp += crop.xpReward;
      harvestedCount += harvested;
      _record('حصاد محصول', '${crop.emoji} ${crop.name} ×$harvested');
      plot.clear();
    }

    if (harvestedCount == 0) {
      if (cleanedInvalidPlot) _commit();
      return null;
    }
    final levelsGained = _addXp(totalXp);
    _commit();
    return HarvestResult(income: 0, xp: totalXp, levelsGained: levelsGained, harvestedCount: harvestedCount);
  }

  int _addXp(int amount) {
    if (amount <= 0) return 0;
    xp = (xp + amount).clamp(0, 1000000000).toInt();
    var gained = 0;
    // Bound the loop defensively if a malformed save somehow contains extreme XP.
    while (xp >= xpNeeded && gained < 10000) {
      xp -= xpNeeded;
      if (level >= 1000000) {
        xp = 0;
        break;
      }
      level++;
      gold = (gold + levelUpGoldReward).clamp(0, 1000000).toInt();
      gained++;
    }
    return gained;
  }

  /// يبيع المحاصيل المخزونة بسعر السوق الحالي مع احتساب الأدوات ومكافآت الحيوانات الأليفة.
  String? sellHarvestedCrop(Crop crop, int qty) {
    if (qty < 1 || qty > 9999) return 'اختر كمية بين 1 و9999';
    final item = ShopData.tryCropById(crop.id);
    if (item == null) return 'هذا المحصول غير موجود في السوق';
    final owned = storedCrop(item.id);
    if (owned < qty) return 'الكمية المخزونة غير كافية';
    final unitPrice = marketSalePrice(item);
    final requested = unitPrice * qty;
    if (requested < 1) return 'تعذر حساب سعر البيع';
    if (requested > 2000000000 - money) return 'رصيدك قريب من الحد الأقصى؛ اصرف جزءاً من الرصيد قبل البيع';
    harvestedCrops[item.id] = owned - qty;
    if (harvestedCrops[item.id] <= 0) harvestedCrops.remove(item.id);
    _trackProgress('sold', qty);
    final credited = _creditMoney(requested);
    _record('بيع محاصيل مخزونة', '${item.emoji} ${item.name} ×$qty', moneyDelta: credited);
    _commit();
    return null;
  }

  String? sellAllHarvestedCrops() {
    if (totalStoredCrops == 0) return 'ما عندك محاصيل مخزونة للبيع';
    var totalRequested = 0;
    final sold = <String, int>{};
    for (final crop in ShopData.crops) {
      final qty = storedCrop(crop.id);
      if (qty <= 0) continue;
      totalRequested += marketSalePrice(crop) * qty;
      sold[crop.id] = qty;
    }
    if (sold.isEmpty) return 'ما عندك محاصيل صالحة للبيع';
    if (totalRequested > 2000000000 - money) return 'قيمة المحاصيل تتجاوز المساحة المتبقية في رصيدك؛ بع المحاصيل على دفعات';
    harvestedCrops.clear();
    _trackProgress('sold', sold.values.fold<int>(0, (sum, qty) => sum + qty));
    final credited = _creditMoney(totalRequested);
    _record('بيع كل المحاصيل المخزونة', '${sold.values.fold<int>(0, (sum, qty) => sum + qty)} محصول', moneyDelta: credited);
    _commit();
    return null;
  }

  // ---------- الحيوانات ----------
  int pendingCycles(Animal animal, DateTime now) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || !item.isProductive || item.cycleSeconds < 1 ||
        ownedAnimals(item.id) == 0) return 0;
    final last = _lastCollect[item.id] ?? now;
    final elapsedSeconds = now.difference(last).inSeconds;
    if (elapsedSeconds <= 0) return 0;
    final cycles = elapsedSeconds ~/ item.cycleSeconds;
    return cycles > maxStoredCycles ? maxStoredCycles : cycles;
  }

  int pendingIncome(Animal animal, DateTime now) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null) return 0;
    final cycles = pendingCycles(item, now);
    final boosted = cycles.clamp(0, boostedCycles(item.id)).toInt();
    final normal = cycles - boosted;
    final base = normal * item.incomePerCycle * ownedAnimals(item.id);
    final bonus = (boosted * item.incomePerCycle * ownedAnimals(item.id) * 1.5).round();
    return base + bonus;
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
  int collectAllAnimals() {
    final now = DateTime.now();
    var total = 0;
    var processedAny = false;
    for (final animal in ShopData.productiveAnimals) {
      final cycles = pendingCycles(animal, now);
      if (cycles == 0) continue;
      processedAny = true;
      final boosted = cycles.clamp(0, boostedCycles(animal.id)).toInt();
      final normal = cycles - boosted;
      final income = normal * animal.incomePerCycle * ownedAnimals(animal.id) +
          (boosted * animal.incomePerCycle * ownedAnimals(animal.id) * 1.5).round();
      final remaining = (2000000000 - money - total).clamp(0, 2000000000).toInt();
      final credited = income.clamp(0, remaining).toInt();
      total += credited;
      _record('تحصيل إنتاج الحيوانات', animal.name, moneyDelta: credited);
      final last = _lastCollect[animal.id] ?? now;
      _lastCollect[animal.id] = cycles >= maxStoredCycles
          ? now
          : last.add(Duration(seconds: cycles * animal.cycleSeconds));
      if (boosted > 0) _boostedCycles[animal.id] = boostedCycles(animal.id) - boosted;
    }
    if (total > 0) money += total;
    if (processedAny) {
      _trackProgress('animalCollections');
      _commit();
    }
    return total;
  }

  int collectAnimal(Animal animal) {
    final item = ShopData.tryAnimalById(animal.id);
    if (item == null || !item.isProductive) return 0;
    final now = DateTime.now();
    final cycles = pendingCycles(item, now);
    if (cycles == 0) return 0;
    final boosted = cycles.clamp(0, boostedCycles(item.id)).toInt();
    final normal = cycles - boosted;
    final requestedIncome = normal * item.incomePerCycle * ownedAnimals(item.id) +
        (boosted * item.incomePerCycle * ownedAnimals(item.id) * 1.5).round();
    final income = _creditMoney(requestedIncome);
    _record('تحصيل إنتاج الحيوانات', item.name, moneyDelta: income);
    final last = _lastCollect[item.id] ?? now;
    _lastCollect[item.id] = cycles >= maxStoredCycles
        ? now
        : last.add(Duration(seconds: cycles * item.cycleSeconds));
    if (boosted > 0) _boostedCycles[item.id] = boostedCycles(item.id) - boosted;
    _trackProgress('animalCollections');
    _commit();
    return income;
  }

  // ---------- الحفظ والتحميل (محلي + Firestore) ----------
  String? uid;
  Timer? _cloudTimer;
  Future<void> _saveQueue = Future<void>.value();
  Future<void> _cloudSaveQueue = Future<void>.value();

  String get _localKey => uid == null ? _saveKey : '${_saveKey}_$uid';

  void setPlayerName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return;
    playerName = cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
    _commit();
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  Map<String, dynamic> _toMap() => {
        'name': playerName,
        'money': money,
        'gold': gold,
        'xp': xp,
        'level': level,
        'seeds': seeds,
        'harvestedCrops': harvestedCrops,
        'animals': animals,
        'animalFeed': animalFeed,
        'waterUnits': waterUnits,
        'boostedCycles': _boostedCycles,
        'tools': tools.toList(),
        'transactions': transactions,
        'lastDailyRewardDate': lastDailyRewardDate,
        'dailyStreak': dailyStreak,
        'dailyProgressDate': dailyProgressDate,
        'dailyProgress': dailyProgress,
        'claimedDailyMissions': claimedDailyMissions.toList(),
        'lifetimeStats': lifetimeStats,
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

  void _resetToDefaults() {
    playerName = 'المزارع';
    money = 50000;
    gold = 50;
    xp = 0;
    level = 1;
    seeds.clear();
    harvestedCrops.clear();
    animals.clear();
    animalFeed = 0;
    waterUnits = 10;
    _boostedCycles.clear();
    tools.clear();
    transactions.clear();
    lastDailyRewardDate = null;
    dailyStreak = 0;
    dailyProgressDate = _dateKey(DateTime.now());
    dailyProgress.clear();
    claimedDailyMissions.clear();
    lifetimeStats.clear();
    claimedAchievements.clear();
    _lastCollect.clear();
    plots = List.generate(startingPlotCount, (_) => Plot());
  }

  void _applyMap(Map<String, dynamic> m) {
    final savedName = m['name'];
    if (savedName is String && savedName.trim().isNotEmpty) {
      final cleaned = savedName.trim().replaceAll(RegExp(r'\s+'), ' ');
      playerName = cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
    }

    money = ((m['money'] is num ? (m['money'] as num).toInt() : money))
        .clamp(0, 2000000000).toInt();
    gold = ((m['gold'] is num ? (m['gold'] as num).toInt() : gold))
        .clamp(0, 1000000).toInt();
    xp = ((m['xp'] is num ? (m['xp'] as num).toInt() : xp))
        .clamp(0, 1000000000).toInt();
    level = ((m['level'] is num ? (m['level'] as num).toInt() : level))
        .clamp(1, 1000000).toInt();

    seeds.clear();
    final savedSeeds = m['seeds'];
    if (savedSeeds is Map) {
      for (final entry in savedSeeds.entries) {
        if (entry.value is num) {
          seeds[entry.key.toString()] = (entry.value as num)
              .toInt().clamp(0, 1000000000).toInt();
        }
      }
    }

    harvestedCrops.clear();
    final savedHarvestedCrops = m['harvestedCrops'];
    if (savedHarvestedCrops is Map) {
      for (final entry in savedHarvestedCrops.entries) {
        final crop = ShopData.tryCropById(entry.key.toString());
        if (crop != null && entry.value is num) {
          final qty = (entry.value as num).toInt().clamp(0, 1000000).toInt();
          if (qty > 0) harvestedCrops[crop.id] = qty;
        }
      }
    }

    animals.clear();
    final savedAnimals = m['animals'];
    if (savedAnimals is Map) {
      for (final entry in savedAnimals.entries) {
        if (entry.value is num) {
          animals[entry.key.toString()] = (entry.value as num)
              .toInt().clamp(0, 1000000000).toInt();
        }
      }
    }

    animalFeed = ((m['animalFeed'] is num ? (m['animalFeed'] as num).toInt() : 0))
        .clamp(0, 1000000).toInt();
    // Old saves receive a small starter water supply for the new farming mechanic.
    waterUnits = ((m['waterUnits'] is num ? (m['waterUnits'] as num).toInt() : 5))
        .clamp(0, 1000000).toInt();
    _boostedCycles
      ..clear();
    final savedBoosts = m['boostedCycles'];
    if (savedBoosts is Map) {
      for (final entry in savedBoosts.entries) {
        final id = entry.key.toString();
        final animal = ShopData.tryAnimalById(id);
        if (animal != null && animal.isProductive && entry.value is num) {
          final count = (entry.value as num).toInt().clamp(0, 30).toInt();
          if (count > 0) _boostedCycles[id] = count;
        }
      }
    }

    tools
      ..clear()
      ..addAll(m['tools'] is List
          ? (m['tools'] as List).map((value) => value.toString())
          : const <String>[]);

    transactions.clear();
    final savedTransactions = m['transactions'];
    if (savedTransactions is List) {
      for (final entry in savedTransactions.whereType<Map>().take(60)) {
        try {
          transactions.add(Map<String, dynamic>.from(entry));
        } catch (_) {
          // Skip a malformed transaction without discarding the rest of the save.
        }
      }
    }

    lastDailyRewardDate = m['lastDailyRewardDate'] is String
        ? m['lastDailyRewardDate'] as String
        : null;
    dailyStreak = ((m['dailyStreak'] is num
            ? (m['dailyStreak'] as num).toInt()
            : 0))
        .clamp(0, 7).toInt();
    dailyProgressDate = m['dailyProgressDate'] is String ? m['dailyProgressDate'] as String : _dateKey(DateTime.now());
    dailyProgress
      ..clear();
    final savedDailyProgress = m['dailyProgress'];
    if (savedDailyProgress is Map) {
      for (final entry in savedDailyProgress.entries) {
        if (entry.value is num) dailyProgress[entry.key.toString()] = (entry.value as num).toInt().clamp(0, 1000000000).toInt();
      }
    }
    claimedDailyMissions
      ..clear()
      ..addAll(m['claimedDailyMissions'] is List ? (m['claimedDailyMissions'] as List).map((v) => v.toString()) : const <String>[]);
    lifetimeStats
      ..clear();
    final savedLifetimeStats = m['lifetimeStats'];
    if (savedLifetimeStats is Map) {
      for (final entry in savedLifetimeStats.entries) {
        if (entry.value is num) lifetimeStats[entry.key.toString()] = (entry.value as num).toInt().clamp(0, 1000000000).toInt();
      }
    }
    claimedAchievements
      ..clear()
      ..addAll(m['claimedAchievements'] is List ? (m['claimedAchievements'] as List).map((v) => v.toString()) : const <String>[]);
    _ensureDailyProgressDate();

    _lastCollect.clear();
    final savedCollect = m['collect'];
    if (savedCollect is Map) {
      for (final entry in savedCollect.entries) {
        final parsed = DateTime.tryParse(entry.value?.toString() ?? '');
        if (parsed != null) _lastCollect[entry.key.toString()] = parsed;
      }
    }

    final savedPlots = m['plots'];
    // Keep legacy saves compatible while restoring expansions up to the game cap.
    final restoredCount = savedPlots is List
        ? savedPlots.length.clamp(startingPlotCount, maxPlotCount).toInt()
        : startingPlotCount;
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
          final rawSeconds = rawPlot['sec'];
          final seconds = rawSeconds is num ? rawSeconds.toInt() : 0;
          plots[i].growSeconds = seconds.clamp(3, 100000000).toInt();
          plots[i].watered = rawPlot['watered'] == true;
        }
      }
    }
  }

  /// يسمح للاختبارات أو لإغلاق التطبيق بانتظار اكتمال آخر حفظ محلي.
  Future<void> waitForLocalSave() => _saveQueue;

  Future<void> _save() {
    // Serialize writes: two rapid actions must not let an older snapshot finish last.
    final key = _localKey;
    final snapshot = jsonEncode(_toMap());
    _saveQueue = _saveQueue.catchError((_) {}).then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, snapshot);
        _scheduleCloudSave();
      } catch (_) {
        // A transient storage error must not crash gameplay. The next action retries.
      }
    });
    return _saveQueue;
  }

  void _scheduleCloudSave() {
    if (uid == null) return;
    _cloudTimer?.cancel();
    _cloudTimer = Timer(const Duration(seconds: 2), _pushCloud);
  }

  Future<void> _pushCloud() {
    final id = uid;
    if (id == null) return Future<void>.value();
    final save = _toMap();
    final publicProfile = <String, dynamic>{
      'uid': id,
      'name': playerName,
      'level': level,
      'money': money,
      'farmPlots': plots.map((plot) => {
        'cropId': plot.cropId,
        'plantedAt': plot.plantedAt?.toIso8601String(),
        'growSeconds': plot.growSeconds,
        'watered': plot.watered,
      }).toList(growable: false),
      'updated': DateTime.now().millisecondsSinceEpoch,
    };
    // Serialize cloud writes as well; prevent delayed requests from overwriting newer saves.
    _cloudSaveQueue = _cloudSaveQueue.catchError((_) {}).then((_) async {
      if (uid != id) return;
      try {
        await FirebaseFirestore.instance.collection('users').doc(id).set(save, SetOptions(merge: true));
        await FirebaseFirestore.instance.collection('publicProfiles').doc(id).set(publicProfile, SetOptions(merge: true));
      } catch (_) {
        // Offline: local save remains available and a later commit will retry.
      }
    });
    return _cloudSaveQueue;
  }

  /// يرفع البيانات فوراً (قبل تسجيل الخروج).
  Future<void> flushSave() async {
    _cloudTimer?.cancel();
    await _pushCloud();
  }

  /// تحميل الحفظ المحلي للعب دون حساب أو إعداد Firebase.
  Future<void> loadLocal() async {
    _cloudTimer?.cancel();
    uid = null;
    _resetToDefaults();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_saveKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) _applyMap(decoded);
      }
    } catch (_) {
      // A damaged local save must not prevent the player from opening the game.
      _resetToDefaults();
    }
    notifyListeners();
  }

  /// تحميل بيانات اللاعب بعد تسجيل الدخول (الأحدث بين السحابة والمحلي).
  Future<void> loadForUser(String userId) async {
    _cloudTimer?.cancel();
    _resetToDefaults();
    uid = userId;

    Map<String, dynamic>? remote;
    Map<String, dynamic>? local;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      remote = snap.data();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw != null) local = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}

    Map<String, dynamic>? chosen;
    if (remote != null && local != null) {
      final r = (remote['updated'] as num?) ?? 0;
      final l = (local['updated'] as num?) ?? 0;
      chosen = r >= l ? remote : local;
    } else {
      chosen = remote ?? local;
    }
    if (chosen != null) {
      try {
        _applyMap(chosen);
      } catch (_) {
        _resetToDefaults();
      }
    }

    final authName = FirebaseAuth.instance.currentUser?.displayName;
    if (authName != null && authName.isNotEmpty) playerName = authName;

    notifyListeners();
    await _save();
  }

  /// تفريغ الحالة عند تسجيل الخروج.
  void reset() {
    _cloudTimer?.cancel();
    uid = null;
    _resetToDefaults();
    notifyListeners();
  }

  @override
  void dispose() {
    _cloudTimer?.cancel();
    super.dispose();
  }
}
