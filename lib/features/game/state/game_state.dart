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
  const HarvestResult({required this.income, required this.xp, required this.levelsGained});

  final int income;
  final int xp;
  final int levelsGained;
}

class GameState extends ChangeNotifier {
  static const _saveKey = 'farm_party_save_v1';
  static const int maxStoredCycles = 10;
  static const int levelUpGoldReward = 5;

  String playerName = 'المزارع';
  int money = 200000; // الدينار العراقي
  int gold = 50; // العملات الذهبية
  int xp = 0;
  int level = 1;

  final Map<String, int> seeds = {};
  final Map<String, int> animals = {};
  final Set<String> tools = {};
  final Map<String, DateTime> _lastCollect = {};
  final List<Plot> plots = List.generate(12, (_) => Plot());
  final List<Map<String, dynamic>> transactions = [];
  String? lastDailyRewardDate;
  int dailyStreak = 0;

  bool get canClaimDailyReward {
    final today = _dateKey(DateTime.now());
    return lastDailyRewardDate != today;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
    dailyStreak = lastDailyRewardDate == yesterday ? dailyStreak + 1 : 1;
    if (dailyStreak > 7) dailyStreak = 7;
    final cashReward = 15000 + (dailyStreak - 1) * 5000;
    final goldReward = dailyStreak == 7 ? 5 : 1;
    money += cashReward;
    gold += goldReward;
    lastDailyRewardDate = _dateKey(now);
    _record('المكافأة اليومية', 'اليوم $dailyStreak من 7', moneyDelta: cashReward, goldDelta: goldReward);
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
  int ownedAnimals(String id) => animals[id] ?? 0;
  bool hasTool(String id) => tools.contains(id);

  // ---------- الشراء ----------
  /// يرجع null عند النجاح، أو رسالة الخطأ.
  String? buySeed(Crop crop, int qty) {
    if (qty < 1 || qty > 9999) return 'اختر كمية بين 1 و9999';
    if (level < crop.requiredLevel) return 'يتطلب المستوى ${crop.requiredLevel}';
    final total = crop.price * qty;
    if (money < total) return 'رصيدك غير كافٍ 💸';
    money -= total;
    seeds[crop.id] = ownedSeeds(crop.id) + qty;
    _record('شراء بذور', '$qty × ${crop.name}', moneyDelta: -total);
    _commit();
    return null;
  }

  /// يبيع البذور الفائضة بسعر استرداد واضح (60% من سعر الشراء).
  /// يرجع null عند النجاح أو رسالة خطأ عند تعذر البيع.
  String? sellSeed(Crop crop, int qty) {
    if (qty < 1 || qty > 9999) return 'اختر كمية بين 1 و9999';
    final owned = ownedSeeds(crop.id);
    if (owned < qty) return 'ما عندك كمية كافية للبيع';
    final unitPrice = (crop.price * 0.6).floor();
    if (unitPrice < 1) return 'لا يمكن بيع هذا العنصر حالياً';
    seeds[crop.id] = owned - qty;
    money += unitPrice * qty;
    _record('بيع بذور', '$qty × ${crop.name}', moneyDelta: unitPrice * qty);
    _commit();
    return null;
  }

  String? buyAnimal(Animal animal) {
    if (money < animal.price) return 'رصيدك غير كافٍ 💸';
    money -= animal.price;
    if (ownedAnimals(animal.id) == 0 && animal.isProductive) {
      _lastCollect[animal.id] = DateTime.now();
    }
    animals[animal.id] = ownedAnimals(animal.id) + 1;
    _record('شراء حيوان', animal.name, moneyDelta: -animal.price);
    _commit();
    return null;
  }

  /// يبيع حيواناً واحداً مقابل 50% من سعر الشراء.
  String? sellAnimal(Animal animal, {int qty = 1}) {
    if (qty < 1 || qty > 99) return 'اختر كمية بين 1 و99';
    final owned = ownedAnimals(animal.id);
    if (owned < qty) return 'ما عندك عدد كافي للبيع';
    final refund = (animal.price * 0.5).floor() * qty;
    if (refund < 1) return 'لا يمكن بيع هذا الحيوان حالياً';
    animals[animal.id] = owned - qty;
    if (animals[animal.id] == 0) {
      animals.remove(animal.id);
      _lastCollect.remove(animal.id);
    }
    money += refund;
    _record('بيع حيوان', '$qty × ${animal.name}', moneyDelta: refund);
    _commit();
    return null;
  }

  String? buyTool(ToolItem tool) {
    if (tools.contains(tool.id)) return 'تملك هذه الأداة بالفعل';
    if (gold < tool.goldPrice) return 'عملاتك الذهبية غير كافية 🪙';
    gold -= tool.goldPrice;
    tools.add(tool.id);
    _record('شراء أداة', tool.name, goldDelta: -tool.goldPrice);
    _commit();
    return null;
  }

  // ---------- المزرعة ----------
  bool plant(int index, Crop crop) {
    final plot = plots[index];
    if (!plot.isEmpty || ownedSeeds(crop.id) < 1) return false;
    seeds[crop.id] = ownedSeeds(crop.id) - 1;
    plot.cropId = crop.id;
    plot.plantedAt = DateTime.now();
    final seconds = (crop.growSeconds * speedFactor).ceil();
    plot.growSeconds = seconds < 3 ? 3 : seconds;
    _commit();
    return true;
  }

  HarvestResult? harvest(int index) {
    final plot = plots[index];
    if (plot.isEmpty || !plot.isReady(DateTime.now())) return null;
    final crop = ShopData.cropById(plot.cropId!);
    final base = crop.sellPrice * yieldMultiplier;
    final income = (base * (100 + petBonusPercent) / 100).round();
    money += income;
    _record('بيع محصول الحصاد', crop.name, moneyDelta: income);
    plot.clear();
    final gained = _addXp(crop.xpReward);
    _commit();
    return HarvestResult(income: income, xp: crop.xpReward, levelsGained: gained);
  }

  int _addXp(int amount) {
    xp += amount;
    var gained = 0;
    while (xp >= xpNeeded) {
      xp -= xpNeeded;
      level++;
      gold += levelUpGoldReward;
      gained++;
    }
    return gained;
  }

  // ---------- الحيوانات ----------
  int pendingCycles(Animal animal, DateTime now) {
    if (!animal.isProductive || ownedAnimals(animal.id) == 0) return 0;
    final last = _lastCollect[animal.id] ?? now;
    final cycles = now.difference(last).inSeconds ~/ animal.cycleSeconds;
    return cycles > maxStoredCycles ? maxStoredCycles : cycles;
  }

  int pendingIncome(Animal animal, DateTime now) =>
      pendingCycles(animal, now) * animal.incomePerCycle * ownedAnimals(animal.id);

  int collectAnimal(Animal animal) {
    final now = DateTime.now();
    final cycles = pendingCycles(animal, now);
    if (cycles == 0) return 0;
    final income = cycles * animal.incomePerCycle * ownedAnimals(animal.id);
    money += income;
    _record('تحصيل إنتاج الحيوانات', animal.name, moneyDelta: income);
    final last = _lastCollect[animal.id] ?? now;
    _lastCollect[animal.id] = cycles >= maxStoredCycles
        ? now
        : last.add(Duration(seconds: cycles * animal.cycleSeconds));
    _commit();
    return income;
  }

  // ---------- الحفظ والتحميل (محلي + Firestore) ----------
  String? uid;
  Timer? _cloudTimer;

  String get _localKey => uid == null ? _saveKey : '${_saveKey}_$uid';

  void setPlayerName(String name) {
    playerName = name;
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
        'animals': animals,
        'tools': tools.toList(),
        'transactions': transactions,
        'lastDailyRewardDate': lastDailyRewardDate,
        'dailyStreak': dailyStreak,
        'collect': _lastCollect.map((k, v) => MapEntry(k, v.toIso8601String())),
        'plots': plots
            .map((p) => {
                  'crop': p.cropId,
                  'at': p.plantedAt?.toIso8601String(),
                  'sec': p.growSeconds,
                })
            .toList(),
        'updated': DateTime.now().millisecondsSinceEpoch,
      };

  void _resetToDefaults() {
    playerName = 'المزارع';
    money = 200000;
    gold = 50;
    xp = 0;
    level = 1;
    seeds.clear();
    animals.clear();
    tools.clear();
    transactions.clear();
    lastDailyRewardDate = null;
    dailyStreak = 0;
    _lastCollect.clear();
    for (final p in plots) {
      p.clear();
    }
  }

  void _applyMap(Map<String, dynamic> m) {
    playerName = (m['name'] as String?) ?? playerName;
    money = ((m['money'] as num?)?.toInt() ?? money).clamp(0, 9000000000000000).toInt();
    gold = ((m['gold'] as num?)?.toInt() ?? gold).clamp(0, 9000000000000000).toInt();
    xp = ((m['xp'] as num?)?.toInt() ?? xp).clamp(0, 9000000000000000).toInt();
    level = ((m['level'] as num?)?.toInt() ?? level).clamp(1, 1000000).toInt();
    seeds
      ..clear()
      ..addAll(((m['seeds'] as Map?) ?? {})
          .map<String, int>((k, v) => MapEntry(k.toString(), ((v as num).toInt()).clamp(0, 1000000000).toInt())));
    animals
      ..clear()
      ..addAll(((m['animals'] as Map?) ?? {})
          .map<String, int>((k, v) => MapEntry(k.toString(), ((v as num).toInt()).clamp(0, 1000000000).toInt())));
    tools
      ..clear()
      ..addAll(((m['tools'] as List?) ?? []).map((e) => e.toString()));
    transactions
      ..clear()
      ..addAll(((m['transactions'] as List?) ?? []).whereType<Map>().take(60).map((e) => Map<String, dynamic>.from(e)));
    lastDailyRewardDate = m['lastDailyRewardDate'] as String?;
    dailyStreak = ((m['dailyStreak'] as num?)?.toInt() ?? 0).clamp(0, 7).toInt();
    _lastCollect
      ..clear()
      ..addAll(((m['collect'] as Map?) ?? {})
          .map<String, DateTime>((k, v) => MapEntry(k.toString(), DateTime.parse(v as String))));
    final savedPlots = (m['plots'] as List?) ?? [];
    for (var i = 0; i < plots.length; i++) {
      plots[i].clear();
      if (i >= savedPlots.length) continue;
      final p = savedPlots[i] as Map;
      final crop = p['crop'] as String?;
      final at = DateTime.tryParse((p['at'] as String?) ?? '');
      if (crop != null && at != null) {
        plots[i].cropId = crop;
        plots[i].plantedAt = at;
        plots[i].growSeconds = (p['sec'] as num?)?.toInt() ?? 0;
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(_toMap()));
    _scheduleCloudSave();
  }

  void _scheduleCloudSave() {
    if (uid == null) return;
    _cloudTimer?.cancel();
    _cloudTimer = Timer(const Duration(seconds: 2), _pushCloud);
  }

  Future<void> _pushCloud() async {
    final id = uid;
    if (id == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .set(_toMap(), SetOptions(merge: true));
    } catch (_) {
      // بدون إنترنت: يبقى الحفظ المحلي ويُرفع لاحقاً مع أول حفظ ناجح
    }
  }

  /// يرفع البيانات فوراً (قبل تسجيل الخروج).
  Future<void> flushSave() async {
    _cloudTimer?.cancel();
    await _pushCloud();
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
