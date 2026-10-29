class DecorItem {
  const DecorItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.requiredLevel,
    required this.description,
    this.sellBonusPercent = 0,
    this.xpBonusPercent = 0,
    this.growBonus = 0,
  });

  final String id;
  final String name;
  final String emoji;
  final int price;
  final int requiredLevel;
  final String description;
  final int sellBonusPercent;
  final int xpBonusPercent;
  final double growBonus;
}

class DecorData {
  static const List<DecorItem> items = [
    DecorItem(
      id: 'scarecrow',
      name: 'الفزاعة',
      emoji: '🧶',
      price: 25000,
      requiredLevel: 3,
      description: 'تحمي المحاصيل وتزيد البيع 3%',
      sellBonusPercent: 3,
    ),
    DecorItem(
      id: 'fence',
      name: 'سياج خشبي',
      emoji: '🪵',
      price: 40000,
      requiredLevel: 5,
      description: 'مظهر أجمل + نمو أسرع 3%',
      growBonus: 0.03,
    ),
    DecorItem(
      id: 'lantern',
      name: 'فوانيس المزرعة',
      emoji: '🏮',
      price: 60000,
      requiredLevel: 8,
      description: 'يزيد الخبرة 8%',
      xpBonusPercent: 8,
    ),
    DecorItem(
      id: 'fountain',
      name: 'نافورة',
      emoji: '⛲',
      price: 150000,
      requiredLevel: 14,
      description: 'نمو أسرع 5% وبيع +5%',
      growBonus: 0.05,
      sellBonusPercent: 5,
    ),
    DecorItem(
      id: 'statue',
      name: 'تمثال المزارع',
      emoji: '🗿',
      price: 280000,
      requiredLevel: 20,
      description: 'هيبة المزرعة: بيع +7% وخبرة +10%',
      sellBonusPercent: 7,
      xpBonusPercent: 10,
    ),
    DecorItem(
      id: 'flowers',
      name: 'حديقة ورود',
      emoji: '🌹',
      price: 90000,
      requiredLevel: 10,
      description: 'جمال يرفع أسعار البيع 4%',
      sellBonusPercent: 4,
    ),
    DecorItem(
      id: 'windmill',
      name: 'طاحونة هواء',
      emoji: '🌬️',
      price: 350000,
      requiredLevel: 25,
      description: 'نمو أسرع 8%',
      growBonus: 0.08,
    ),
    DecorItem(
      id: 'flag',
      name: 'علم المزرعة',
      emoji: '🚩',
      price: 50000,
      requiredLevel: 6,
      description: 'رمز فخر: خبرة +5%',
      xpBonusPercent: 5,
    ),
  ];

  static DecorItem? tryById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }
}
