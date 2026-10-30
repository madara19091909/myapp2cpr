class BuildingDef {
  const BuildingDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.requiredLevel,
    required this.description,
    this.growSpeedBonus = 0,
    this.sellBonusPercent = 0,
    this.animalIncomeBonus = 0,
    this.waterSaveChance = 0,
    this.xpBonusPercent = 0,
  });

  final String id;
  final String name;
  final String emoji;
  final int price;
  final int requiredLevel;
  final String description;

  /// تقليل وقت النمو كنسبة (0.10 = -10%)
  final double growSpeedBonus;

  /// زيادة سعر البيع %
  final int sellBonusPercent;

  /// زيادة دخل الحيوانات %
  final int animalIncomeBonus;

  /// احتمال عدم استهلاك الماء عند السقي %
  final int waterSaveChance;

  /// زيادة XP %
  final int xpBonusPercent;
}

class RecipeDef {
  const RecipeDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.inputCropId,
    required this.inputQty,
    required this.outputId,
    required this.outputName,
    required this.outputEmoji,
    required this.outputSellPrice,
    required this.craftSeconds,
    required this.requiredLevel,
    required this.buildingId,
  });

  final String id;
  final String name;
  final String emoji;
  final String inputCropId;
  final int inputQty;
  final String outputId;
  final String outputName;
  final String outputEmoji;
  final int outputSellPrice;
  final int craftSeconds;
  final int requiredLevel;
  final String buildingId;
}

class BuildingData {
  static const List<BuildingDef> buildings = [
    BuildingDef(
      id: 'greenhouse',
      name: 'البيت الزجاجي',
      emoji: '🏡',
      price: 120000,
      requiredLevel: 5,
      description: 'يقلل وقت نمو كل المحاصيل بنسبة 10%',
      growSpeedBonus: 0.06,
    ),
    BuildingDef(
      id: 'barn',
      name: 'الحظيرة',
      emoji: '🏚️',
      price: 200000,
      requiredLevel: 8,
      description: 'يزيد دخل الحيوانات المنتجة بنسبة 15%',
      animalIncomeBonus: 8,
    ),
    BuildingDef(
      id: 'well',
      name: 'البئر',
      emoji: '🪨',
      price: 90000,
      requiredLevel: 4,
      description: 'احتمال 30% أن السقي لا يستهلك ماء',
      waterSaveChance: 30,
    ),
    BuildingDef(
      id: 'silo',
      name: 'الصومعة',
      emoji: '🗼',
      price: 150000,
      requiredLevel: 10,
      description: 'يزيد أسعار بيع المحاصيل بنسبة 8%',
      sellBonusPercent: 3,
    ),
    BuildingDef(
      id: 'mill',
      name: 'المطحنة',
      emoji: '⚙️',
      price: 250000,
      requiredLevel: 12,
      description: 'تفتح تصنيع الدقيق من القمح والذرة',
    ),
    BuildingDef(
      id: 'bakery',
      name: 'المخبز',
      emoji: '🍞',
      price: 400000,
      requiredLevel: 18,
      description: 'تفتح تصنيع الخبز والكعك من الدقيق',
    ),
    BuildingDef(
      id: 'school',
      name: 'مدرسة المزرعة',
      emoji: '📚',
      price: 180000,
      requiredLevel: 7,
      description: 'يزيد خبرة الحصاد بنسبة 20%',
      xpBonusPercent: 10,
    ),
    BuildingDef(
      id: 'warehouse',
      name: 'المستودع',
      emoji: '📦',
      price: 300000,
      requiredLevel: 15,
      description: 'يزيد أسعار البيع بنسبة 5% إضافية',
      sellBonusPercent: 2,
    ),
  ];

  static const List<RecipeDef> recipes = [
    RecipeDef(
      id: 'flour_wheat',
      name: 'دقيق قمح',
      emoji: '🫓',
      inputCropId: 'wheat',
      inputQty: 3,
      outputId: 'flour',
      outputName: 'دقيق',
      outputEmoji: '🫓',
      outputSellPrice: 12100,
      craftSeconds: 480,
      requiredLevel: 12,
      buildingId: 'mill',
    ),
    RecipeDef(
      id: 'flour_corn',
      name: 'دقيق ذرة',
      emoji: '🌽',
      inputCropId: 'corn',
      inputQty: 2,
      outputId: 'corn_flour',
      outputName: 'دقيق ذرة',
      outputEmoji: '🟡',
      outputSellPrice: 20900,
      craftSeconds: 240,
      requiredLevel: 12,
      buildingId: 'mill',
    ),
    RecipeDef(
      id: 'bread',
      name: 'خبز طازج',
      emoji: '🍞',
      inputCropId: 'wheat',
      inputQty: 5,
      outputId: 'bread',
      outputName: 'خبز',
      outputEmoji: '🍞',
      outputSellPrice: 23100,
      craftSeconds: 360,
      requiredLevel: 18,
      buildingId: 'bakery',
    ),
    RecipeDef(
      id: 'cake',
      name: 'كعكة المزرعة',
      emoji: '🍰',
      inputCropId: 'strawberry',
      inputQty: 2,
      outputId: 'cake',
      outputName: 'كعكة',
      outputEmoji: '🍰',
      outputSellPrice: 6600000,
      craftSeconds: 900,
      requiredLevel: 45,
      buildingId: 'bakery',
    ),
    RecipeDef(
      id: 'juice',
      name: 'عصير برتقال',
      emoji: '🧃',
      inputCropId: 'orange',
      inputQty: 2,
      outputId: 'juice',
      outputName: 'عصير',
      outputEmoji: '🧃',
      outputSellPrice: 2090000,
      craftSeconds: 480,
      requiredLevel: 30,
      buildingId: 'bakery',
    ),
    RecipeDef(
      id: 'jam_grape',
      name: 'مربى عنب',
      emoji: '🫙',
      inputCropId: 'grape',
      inputQty: 2,
      outputId: 'jam',
      outputName: 'مربى',
      outputEmoji: '🫙',
      outputSellPrice: 3850000,
      craftSeconds: 240,
      requiredLevel: 36,
      buildingId: 'bakery',
    ),
    RecipeDef(
      id: 'chips',
      name: 'شيبس بطاطس',
      emoji: '🍟',
      inputCropId: 'potato',
      inputQty: 3,
      outputId: 'chips',
      outputName: 'شيبس',
      outputEmoji: '🍟',
      outputSellPrice: 412500,
      craftSeconds: 150,
      requiredLevel: 15,
      buildingId: 'mill',
    ),
  ];

  static BuildingDef? tryById(String id) {
    for (final b in buildings) {
      if (b.id == id) return b;
    }
    return null;
  }

  static RecipeDef? tryRecipe(String id) {
    for (final r in recipes) {
      if (r.id == id) return r;
    }
    return null;
  }
}
