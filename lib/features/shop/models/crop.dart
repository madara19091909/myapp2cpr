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
  final int price;
  final int requiredLevel;
  final int growSeconds;

  /// هامش البيع مرفوع حتى تبقى الزراعة مربحة بصورة معقولة بعد ضريبة 25%
  /// ورسوم السوق، مع بقاء سعر شراء البذور كما هو.
  int get sellPrice {
    final margin = requiredLevel <= 5
        ? 1.65
        : requiredLevel <= 20
            ? 1.70
            : 1.75;
    return (price * margin).round();
  }

  int get xpReward => 2 + (requiredLevel ~/ 2) + (growSeconds ~/ 700);
}
