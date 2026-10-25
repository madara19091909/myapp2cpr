import 'package:farm_party/features/game/state/game_state.dart';
import 'package:farm_party/features/shop/data/shop_data.dart';
import 'package:farm_party/features/shop/models/animal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test('crops are sorted by required level', () {
    for (var i = 1; i < ShopData.crops.length; i++) {
      expect(ShopData.crops[i].requiredLevel >= ShopData.crops[i - 1].requiredLevel, true);
    }
  });

  test('selling seeds only sells owned quantity and credits 60 percent', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buySeed(crop, 3), isNull);
    final afterBuy = game.money;
    expect(game.ownedSeeds(crop.id), 3);

    expect(game.sellSeed(crop, 2), isNull);
    expect(game.ownedSeeds(crop.id), 1);
    expect(game.money, afterBuy + (crop.price * 0.6).floor() * 2);

    final balance = game.money;
    expect(game.sellSeed(crop, 2), isNotNull);
    expect(game.ownedSeeds(crop.id), 1);
    expect(game.money, balance);
    game.dispose();
  });



  test('selling an animal requires ownership and refunds half the purchase price', () {
    final game = GameState();
    const animal = Animal(id: 'test_chicken', name: 'دجاجة اختبار', emoji: '🐔', price: 1000);
    expect(game.sellAnimal(animal), isNotNull);
    expect(game.buyAnimal(animal), isNull);
    final balance = game.money;
    expect(game.sellAnimal(animal), isNull);
    expect(game.money, balance + 500);
    expect(game.ownedAnimals(animal.id), 0);
    expect(game.transactions.first['title'], 'بيع حيوان');
    game.dispose();
  });

  test('daily reward can only be claimed once per day and creates a transaction', () {
    final game = GameState();
    final startingMoney = game.money;
    final startingGold = game.gold;
    expect(game.canClaimDailyReward, isTrue);
    expect(game.claimDailyReward(), isNull);
    expect(game.money, startingMoney + 15000);
    expect(game.gold, startingGold + 1);
    expect(game.canClaimDailyReward, isFalse);
    expect(game.claimDailyReward(), isNotNull);
    expect(game.transactions.first['title'], 'المكافأة اليومية');
    game.dispose();
  });

  test('purchases are recorded in transaction history', () {
    final game = GameState();
    final crop = ShopData.crops.first;
    expect(game.buySeed(crop, 2), isNull);
    expect(game.transactions.first['title'], 'شراء بذور');
    expect(game.transactions.first['money'], -crop.price * 2);
    game.dispose();
  });

  test('buying seeds rejects invalid quantities and insufficient funds', () {
    final game = GameState();
    final expensiveCrop = ShopData.crops.last;
    expect(game.buySeed(expensiveCrop, 1), contains('المستوى'));
    expect(game.buySeed(ShopData.crops.first, 0), isNotNull);
    game.money = 0;
    expect(game.buySeed(ShopData.crops.first, 1), contains('غير كافٍ'));
    game.dispose();
  });
}
