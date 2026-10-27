import 'package:flutter_test/flutter_test.dart';
import 'package:farm_party/features/game/state/game_state.dart';
import 'package:farm_party/features/shop/data/shop_data.dart';

void main() {
  test('economy starts at configured Iraqi dinar balance', () {
    final game = GameState();
    expect(game.money, 50000);
    expect(GameState.levelUpGoldReward, 2);
    game.dispose();
  });

  test('crop sell price is capped to the configured 115 percent', () {
    for (final crop in ShopData.crops) {
      expect(crop.sellPrice, (crop.price * 1.15).round());
    }
  });

  test('daily market price stays stable for the same crop and date', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    final date = DateTime(2026, 10, 27);
    expect(game.marketPricePercent(crop, date: date),
        game.marketPricePercent(crop, date: date));
    expect(game.marketPricePercent(crop, date: date), inInclusiveRange(85, 120));
    expect(game.marketSalePrice(crop, date: date), greaterThan(0));
    game.dispose();
  });

  test('selling stored crops uses the current market price and records credited cash', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    game.harvestedCrops[crop.id] = 2;
    final expected = game.marketSalePrice(crop) * 2;
    final startingMoney = game.money;
    expect(game.sellHarvestedCrop(crop, 2), isNull);
    expect(game.money, startingMoney + expected);
    expect(game.storedCrop(crop.id), 0);
    expect(game.transactions.first['money'], expected);
    game.dispose();
  });

  test('pickaxe produces two stored crops per ready plot and tracks actual yield', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buyTool(ShopData.tools.firstWhere((tool) => tool.id == 'pickaxe')), isNull);
    expect(game.buySeed(crop, 1), isNull);
    expect(game.plant(0, crop), isTrue);
    game.plots[0].plantedAt = DateTime.now().subtract(Duration(seconds: crop.growSeconds + 10));
    final result = game.harvest(0);
    expect(result, isNotNull);
    expect(result!.harvestedCount, 2);
    expect(game.storedCrop(crop.id), 2);
    expect(game.lifetimeStats['harvested'], 2);
    game.dispose();
  });

  test('animal collection total is zero when no animals are owned', () {
    final game = GameState();
    expect(game.totalPendingAnimalIncome, 0);
    expect(game.collectAllAnimals(), 0);
    game.dispose();
  });


  test('pickaxe doubles harvested crop quantity without inflating unit price', () {
    final game = GameState();
    expect(game.yieldMultiplier, 1);
    expect(game.buyTool(ShopData.tools.firstWhere((tool) => tool.id == 'pickaxe')), isNull);
    expect(game.yieldMultiplier, 2);
    final crop = ShopData.crops.first;
    final priceBefore = game.marketSalePrice(crop);
    expect(game.buyTool(ShopData.tools.firstWhere((tool) => tool.id == 'pickaxe')), isNotNull);
    expect(game.marketSalePrice(crop), priceBefore);
    game.dispose();
  });


  test('harvest all ready crops clears plots and grants combined rewards', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buySeed(crop, 2), isNull);
    expect(game.plant(0, crop), isTrue);
    expect(game.plant(1, crop), isTrue);
    final plantedAt = DateTime.now().subtract(Duration(seconds: crop.growSeconds + 10));
    game.plots[0].plantedAt = plantedAt;
    game.plots[1].plantedAt = plantedAt;
    final result = game.harvestAllReady();
    expect(result, isNotNull);
    expect(result!.income, 0); // Harvest stores crops; sale is a separate inventory action.
    expect(result.xp, crop.xpReward * 2);
    expect(game.plots[0].isEmpty, isTrue);
    expect(game.plots[1].isEmpty, isTrue);
    expect(game.harvestAllReady(), isNull);
    game.dispose();
  });



  test('selling the final seed removes its empty inventory entry', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    game.seeds[crop.id] = 1;
    expect(game.sellSeed(crop, 1), isNull);
    expect(game.ownedSeeds(crop.id), 0);
    expect(game.seeds.containsKey(crop.id), isFalse);
    game.dispose();
  });

  test('crop prices and growth times always come from the shop catalogue', () {
    final game = GameState();
    const forgedCrop = Crop(
      id: 'wheat',
      name: 'قمح مزيف',
      emoji: '🌾',
      price: 1,
      requiredLevel: 1,
      growSeconds: 1,
    );
    final startingMoney = game.money;
    expect(game.buySeed(forgedCrop, 1), isNull);
    expect(game.money, startingMoney - ShopData.crops.first.price);
    expect(game.plant(0, forgedCrop), isTrue);
    expect(game.plots[0].growSeconds, ShopData.crops.first.growSeconds);
    game.dispose();
  });

  test('axe and bucket apply their advertised growth-time reductions', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buyTool(ShopData.tools.firstWhere((tool) => tool.id == 'axe')), isNull);
    expect(game.buyTool(ShopData.tools.firstWhere((tool) => tool.id == 'bucket')), isNull);
    expect(game.buySeed(crop, 1), isNull);
    expect(game.plant(0, crop), isTrue);
    expect(game.plots[0].growSeconds, (crop.growSeconds * 0.75 * 0.5).ceil());
    game.dispose();
  });

  test('watering a planted crop consumes one water and reduces growth time once', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buySeed(crop, 1), isNull);
    expect(game.plant(0, crop), isTrue);
    final before = game.plots[0].remainingSeconds(DateTime.now());
    final initialWater = game.waterUnits;
    expect(game.waterPlot(0), isNull);
    final after = game.plots[0].remainingSeconds(DateTime.now());
    expect(game.waterUnits, initialWater - 1);
    expect(game.plots[0].watered, isTrue);
    expect(after, lessThan(before));
    expect(game.waterPlot(0), isNotNull);
    expect(game.waterUnits, initialWater - 1);
    game.dispose();
  });

  test('water purchase validates funds and stock limits', () {
    final game = GameState();
    final before = game.waterUnits;
    expect(game.buyWater(), isNull);
    expect(game.waterUnits, before + GameState.waterPackSize);
    expect(game.money, 50000 - GameState.waterPackPrice);
    game.money = 0;
    final currentWater = game.waterUnits;
    expect(game.buyWater(), isNotNull);
    expect(game.waterUnits, currentWater);
    game.dispose();
  });

  test('planting rejects crops locked behind a higher level', () {
    final game = GameState();
    final lockedCrop = ShopData.crops.firstWhere((crop) => crop.requiredLevel > game.level);
    game.seeds[lockedCrop.id] = 1;
    expect(game.plant(0, lockedCrop), isFalse);
    expect(game.ownedSeeds(lockedCrop.id), 1);
    expect(game.plots[0].isEmpty, isTrue);
    game.dispose();
  });

  test('cash rewards are capped without recording money that was not credited', () {
    final game = GameState();
    game.money = 2000000000 - 500;
    expect(game.claimDailyReward(), isNull);
    expect(game.money, 2000000000);
    expect(game.transactions.first['money'], 500);
    game.dispose();
  });


  test('daily missions track planting and reward can only be claimed once', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buySeed(crop, 3), isNull);
    expect(game.plant(0, crop), isTrue);
    expect(game.plant(1, crop), isTrue);
    expect(game.plant(2, crop), isTrue);
    final mission = GameState.dailyMissionDefinitions.firstWhere((m) => m['id'] == 'plant_3');
    expect(game.dailyMissionProgress(mission), 3);
    final before = game.money;
    expect(game.claimDailyMission('plant_3'), isNull);
    expect(game.money, greaterThan(before));
    expect(game.claimDailyMission('plant_3'), isNotNull);
    game.dispose();
  });

  test('achievement rewards are one-time and lifetime progress is tracked', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buySeed(crop, 1), isNull);
    expect(game.plant(0, crop), isTrue);
    final achievement = GameState.achievementDefinitions.firstWhere((a) => a['id'] == 'first_plant');
    expect(game.canClaimAchievement(achievement), isTrue);
    expect(game.claimAchievement('first_plant'), isNull);
    expect(game.claimAchievement('first_plant'), isNotNull);
    game.dispose();
  });

  test('productive animal cycle income is 1 percent of purchase price', () {
    for (final animal in ShopData.productiveAnimals) {
      expect(animal.incomePerCycle, (animal.price * 0.01).round());
    }
  });
}
