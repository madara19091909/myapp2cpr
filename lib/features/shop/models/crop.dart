class Crop {
  const Crop({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.requiredLevel,
    required this.growSeconds,
  });

  final String id;
  final String name;
  final String emoji;

  /// سعر البذرة بالدينار العراقي
  final int price;
  final int requiredLevel;
  final int growSeconds;

  /// قيمة البيع الأساسية للمحصول (115% من سعر البذرة).
  int get sellPrice => (price * 1.15).round();

  /// الخبرة المكتسبة عند الحصاد
  int get xpReward => 10 + requiredLevel * 3;
}
