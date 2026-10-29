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

  /// هامش بيع مضبوط: ربح قليل في البداية ويزداد ببطء
  int get sellPrice {
    // مبكر ~18% | متوسط ~25% | متأخر ~32%
    final margin = requiredLevel <= 5
        ? 1.18
        : requiredLevel <= 20
            ? 1.25
            : 1.32;
    return (price * margin).round();
  }

  /// خبرة معتدلة — ما ترفع المستوى بسرعة
  int get xpReward => 5 + (requiredLevel * 2) + (growSeconds ~/ 150);
}
