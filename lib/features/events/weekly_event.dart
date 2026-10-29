class WeeklyEvent {
  const WeeklyEvent({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.sellBonusPercent,
    required this.growMultiplier,
    required this.xpBonusPercent,
    required this.featuredCropId,
  });

  final String id;
  final String title;
  final String emoji;
  final String description;
  final int sellBonusPercent;
  final double growMultiplier;
  final int xpBonusPercent;
  final String? featuredCropId;

  static const List<WeeklyEvent> catalog = [
    WeeklyEvent(
      id: 'harvest_fest',
      title: 'مهرجان الحصاد',
      emoji: '🎊',
      description: 'أسعار البيع أعلى هذا الأسبوع',
      sellBonusPercent: 12,
      growMultiplier: 1.0,
      xpBonusPercent: 0,
      featuredCropId: null,
    ),
    WeeklyEvent(
      id: 'rain_week',
      title: 'أسبوع المطر',
      emoji: '🌧️',
      description: 'النمو أسرع لكل المحاصيل',
      sellBonusPercent: 0,
      growMultiplier: 0.88,
      xpBonusPercent: 5,
      featuredCropId: null,
    ),
    WeeklyEvent(
      id: 'wheat_boost',
      title: 'موسم القمح',
      emoji: '🌾',
      description: 'القمح أغلى والنمو أسرع قليلاً',
      sellBonusPercent: 5,
      growMultiplier: 0.95,
      xpBonusPercent: 0,
      featuredCropId: 'wheat',
    ),
    WeeklyEvent(
      id: 'xp_rush',
      title: 'اندفاع الخبرة',
      emoji: '⭐',
      description: 'خبرة مضاعفة تقريباً من الحصاد',
      sellBonusPercent: 0,
      growMultiplier: 1.0,
      xpBonusPercent: 40,
      featuredCropId: null,
    ),
    WeeklyEvent(
      id: 'market_day',
      title: 'يوم السوق الكبير',
      emoji: '🏪',
      description: 'كل المنتجات والمحاصيل بسعر أفضل',
      sellBonusPercent: 18,
      growMultiplier: 1.05,
      xpBonusPercent: 0,
      featuredCropId: null,
    ),
    WeeklyEvent(
      id: 'quiet_week',
      title: 'أسبوع هادئ',
      emoji: '🍃',
      description: 'لا مكافآت خاصة — موسم عادي',
      sellBonusPercent: 0,
      growMultiplier: 1.0,
      xpBonusPercent: 0,
      featuredCropId: null,
    ),
  ];

  /// حدث ثابت لنفس رقم الأسبوع في السنة.
  static WeeklyEvent current([DateTime? date]) {
    final d = date ?? DateTime.now();
    final week = int.parse('${d.year}${((d.difference(DateTime(d.year)).inDays) ~/ 7)}');
    return catalog[week % catalog.length];
  }
}
