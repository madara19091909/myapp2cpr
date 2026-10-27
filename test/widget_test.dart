import 'package:farm_party/app.dart';
import 'package:farm_party/features/game/state/game_state.dart';
import 'package:farm_party/features/shop/data/shop_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});


  testWidgets('offline loader opens the farm without Firebase', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<GameState>(
        create: (_) => GameState(),
        child: const MaterialApp(home: OfflineGameLoader()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('مزرعتي'), findsOneWidget);
    expect(find.text('ازرع، انتظر، واحصد أرباحك'), findsOneWidget);
    await tester.tap(find.text('الأصدقاء'));
    await tester.pumpAndSettle();
    expect(find.text('المنافسات الجماعية'), findsOneWidget);
  });

  test('plant and harvest safely reject invalid plot indexes', () {
    final game = GameState();
    expect(game.plant(-1, ShopData.crops.first), isFalse);
    expect(game.plant(game.plots.length, ShopData.crops.first), isFalse);
    expect(game.harvest(-1), isNull);
    expect(game.harvest(game.plots.length), isNull);
    game.dispose();
  });


  test('local loading tolerates malformed fields and unknown saved crops', () async {
    SharedPreferences.setMockInitialValues({
      'farm_party_save_v1': '''{"name":"  مزارع تجريبي ","money":12345,"gold":10,"seeds":{"wheat":2,"bad":"x"},"animals":{"chicken":1,"bad":"x"},"plots":[{"crop":"missing_crop","at":"2026-01-01T00:00:00.000","sec":20}]}''' ,
    });
    final game = GameState();
    await game.loadLocal();
    expect(game.money, 12345);
    expect(game.playerName, 'مزارع تجريبي');
    expect(game.ownedSeeds('wheat'), 2);
    expect(game.ownedSeeds('bad'), 0);
    expect(game.plots.first.isEmpty, isTrue);
    game.dispose();
  });

  test('player name is trimmed, normalized and bounded', () {
    final game = GameState();
    game.setPlayerName('  مزارع   بغداد  ');
    expect(game.playerName, 'مزارع بغداد');
    game.setPlayerName('   ');
    expect(game.playerName, 'مزارع بغداد');
    game.setPlayerName(List<String>.filled(40, 'أ').join());
    expect(game.playerName.length, 24);
    game.dispose();
  });


  test('local mode restores a saved game without a user account', () async {
    final game = GameState();
    game.setPlayerName('مزارع محلي');
    await game.waitForLocalSave();
    final restored = GameState();
    await restored.loadLocal();
    expect(restored.uid, isNull);
    expect(restored.playerName, 'مزارع محلي');
    restored.dispose();
    game.dispose();
  });


  test('daily reward cycle returns to day one after day seven', () {
    final game = GameState();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    game.lastDailyRewardDate =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    game.dailyStreak = 7;
    final goldBefore = game.gold;
    expect(game.claimDailyReward(), isNull);
    expect(game.dailyStreak, 1);
    expect(game.gold, goldBefore);
    game.dispose();
  });

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
    final animal = ShopData.productiveAnimals.first;
    game.money = animal.price;
    expect(game.sellAnimal(animal), isNotNull);
    expect(game.buyAnimal(animal), isNull);
    final balance = game.money;
    expect(game.sellAnimal(animal), isNull);
    expect(game.money, balance + (animal.price * 0.5).floor());
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
    expect(game.money, startingMoney + 2000);
    expect(game.gold, startingGold);
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
