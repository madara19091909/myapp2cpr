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
  final int petBonusPercent;

  /// دخل شبه رمزي — الزراعة هي المصدر الأساسي
  int get incomePerCycle => isProductive ? (price * 0.0018).round().clamp(40, 999999999) : 0;
}
