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

  /// ربح ضيق: مبكر أوضح، متوسط شحيح، متأخر يعتمد على السوق/التأمين/البونص.
  int get sellPrice {
    final margin = requiredLevel <= 5
        ? 1.28
        : requiredLevel <= 20
            ? 1.25
            : 1.27;
    return (price * margin).round();
  }

  int get xpReward => 2 + (requiredLevel ~/ 2) + (growSeconds ~/ 700);
}
