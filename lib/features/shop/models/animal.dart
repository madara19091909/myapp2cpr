class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    this.isProductive = true,
    this.cycleSeconds = 60,
    this.petBonusPercent = 0,
  });

  final String id;
  final String name;
  final String emoji;
  final int price;
  final bool isProductive;
  final int cycleSeconds;

  /// نسبة زيادة أرباح الحصاد لكل حيوان أليف
  final int petBonusPercent;

  /// دخل الدورة الواحدة للحيوان الإنتاجي (5% من سعره)
  int get incomePerCycle => isProductive ? (price * 0.05).round() : 0;
}
