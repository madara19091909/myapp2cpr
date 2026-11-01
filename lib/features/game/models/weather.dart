enum WeatherType { sunny, cloudy, rainy, storm, heat }

class WeatherInfo {
  const WeatherInfo({
    required this.type,
    required this.name,
    required this.emoji,
    required this.growMultiplier,
    required this.marketBonus,
    required this.description,
  });

  final WeatherType type;
  final String name;
  final String emoji;
  final double growMultiplier;
  final int marketBonus;
  final String description;

  static WeatherInfo fromType(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return const WeatherInfo(
          type: WeatherType.sunny,
          name: 'مشمس',
          emoji: '☀️',
          growMultiplier: 0.92,
          marketBonus: 0,
          description: 'نمو أسرع قليلاً',
        );
      case WeatherType.cloudy:
        return const WeatherInfo(
          type: WeatherType.cloudy,
          name: 'غائم',
          emoji: '☁️',
          growMultiplier: 1.0,
          marketBonus: 0,
          description: 'طقس عادي',
        );
      case WeatherType.rainy:
        return const WeatherInfo(
          type: WeatherType.rainy,
          name: 'ممطر',
          emoji: '🌧️',
          growMultiplier: 0.85,
          marketBonus: 5,
          description: 'نمو أسرع + سوق أفضل',
        );
      case WeatherType.storm:
        return const WeatherInfo(
          type: WeatherType.storm,
          name: 'عاصفة',
          emoji: '⛈️',
          growMultiplier: 1.25,
          marketBonus: -8,
          description: 'نمو أبطأ وسوق أضعف',
        );
      case WeatherType.heat:
        return const WeatherInfo(
          type: WeatherType.heat,
          name: 'حار',
          emoji: '🔥',
          growMultiplier: 1.15,
          marketBonus: 10,
          description: 'نمو أبطأ لكن أسعار أعلى',
        );
    }
  }

  /// طقس ثابت لنفس اليوم حسب التاريخ.
  static WeatherInfo forDate(DateTime date) {
    final key = date.year * 10000 + date.month * 100 + date.day;
    final idx = key % WeatherType.values.length;
    return fromType(WeatherType.values[idx]);
  }
}

enum SeasonType { spring, summer, autumn, winter }

class SeasonInfo {
  const SeasonInfo({
    required this.type,
    required this.name,
    required this.emoji,
    required this.sellBonus,
    required this.xpBonus,
  });

  final SeasonType type;
  final String name;
  final String emoji;
  final int sellBonus;
  final int xpBonus;

  static SeasonInfo current([DateTime? date]) {
    final m = (date ?? DateTime.now()).month;
    if (m >= 3 && m <= 5) {
      return const SeasonInfo(type: SeasonType.spring, name: 'الربيع', emoji: '🌸', sellBonus: 5, xpBonus: 10);
    }
    if (m >= 6 && m <= 8) {
      return const SeasonInfo(type: SeasonType.summer, name: 'الصيف', emoji: '🌻', sellBonus: 0, xpBonus: 0);
    }
    if (m >= 9 && m <= 11) {
      return const SeasonInfo(type: SeasonType.autumn, name: 'الخريف', emoji: '🍂', sellBonus: 8, xpBonus: 5);
    }
    return const SeasonInfo(type: SeasonType.winter, name: 'الشتاء', emoji: '❄️', sellBonus: -5, xpBonus: 15);
  }
}
