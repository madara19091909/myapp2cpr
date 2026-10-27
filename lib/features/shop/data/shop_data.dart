import '../models/animal.dart';
import '../models/crop.dart';
import '../models/tool_item.dart';

class ShopData {
  static const List<Crop> crops = [
    Crop(id: 'wheat', name: 'القمح', emoji: '🌾', price: 10000, requiredLevel: 1, growSeconds: 60),
    Crop(id: 'corn', name: 'الذرة', emoji: '🌽', price: 25000, requiredLevel: 3, growSeconds: 120),
    Crop(id: 'carrot', name: 'الجزر', emoji: '🥕', price: 57000, requiredLevel: 5, growSeconds: 180),
    Crop(id: 'cucumber', name: 'الخيار', emoji: '🥒', price: 123000, requiredLevel: 7, growSeconds: 240),
    Crop(id: 'tomato', name: 'الطماطم', emoji: '🍅', price: 257000, requiredLevel: 10, growSeconds: 300),
    Crop(id: 'potato', name: 'البطاطس', emoji: '🥔', price: 527000, requiredLevel: 14, growSeconds: 420),
    Crop(id: 'lemon', name: 'الليمون', emoji: '🍋', price: 1800000, requiredLevel: 18, growSeconds: 600),
    Crop(id: 'apple', name: 'التفاح', emoji: '🍎', price: 3000000, requiredLevel: 25, growSeconds: 900),
    Crop(id: 'orange', name: 'البرتقال', emoji: '🍊', price: 5000000, requiredLevel: 30, growSeconds: 1200),
    Crop(id: 'grape', name: 'العنب', emoji: '🍇', price: 8000000, requiredLevel: 37, growSeconds: 1800),
    Crop(id: 'strawberry', name: 'الفراولة', emoji: '🍓', price: 12000000, requiredLevel: 45, growSeconds: 2400),
    Crop(id: 'berry', name: 'التوت', emoji: '🫐', price: 18000000, requiredLevel: 60, growSeconds: 3000),
    Crop(id: 'cherry', name: 'الكرز', emoji: '🍒', price: 65000000, requiredLevel: 75, growSeconds: 3600),
    Crop(id: 'pineapple', name: 'الأناناس', emoji: '🍍', price: 90000000, requiredLevel: 100, growSeconds: 5400),
    Crop(id: 'coconut', name: 'جوز الهند', emoji: '🥥', price: 125000000, requiredLevel: 120, growSeconds: 7200),
  ];

  static const List<Animal> productiveAnimals = [
    Animal(id: 'chicken', name: 'الدجاج', emoji: '🐔', price: 100000, cycleSeconds: 300),
    Animal(id: 'cow', name: 'البقر', emoji: '🐄', price: 250000, cycleSeconds: 600),
    Animal(id: 'sheep', name: 'الغنم', emoji: '🐑', price: 750000, cycleSeconds: 900),
    Animal(id: 'fish', name: 'السمك', emoji: '🐟', price: 1500000, cycleSeconds: 900),
    Animal(id: 'birds', name: 'الطيور', emoji: '🦜', price: 2000000, cycleSeconds: 900),
    Animal(id: 'bees', name: 'النحل', emoji: '🐝', price: 1000000, cycleSeconds: 600),
  ];

  static const List<Animal> petAnimals = [
    Animal(id: 'cat', name: 'القطط', emoji: '🐱', price: 120000, isProductive: false, petBonusPercent: 1),
    Animal(id: 'dog', name: 'الكلاب', emoji: '🐶', price: 360000, isProductive: false, petBonusPercent: 2),
    Animal(id: 'horse', name: 'الخيول', emoji: '🐴', price: 950000, isProductive: false, petBonusPercent: 4),
  ];

  static const List<ToolItem> tools = [
    ToolItem(id: 'axe', name: 'الفأس', emoji: '🪓', goldPrice: 15, description: 'يقلل وقت نمو المحاصيل بنسبة 25%'),
    ToolItem(id: 'bucket', name: 'الدلو', emoji: '🪣', goldPrice: 20, description: 'يقلل وقت نمو المحاصيل للنصف بشكل دائم'),
    ToolItem(id: 'pickaxe', name: 'المعول', emoji: '⛏️', goldPrice: 30, description: 'يضاعف كمية المحصول عند الحصاد (×2) بشكل دائم'),
  ];

  static ToolItem? tryToolById(String id) {
    for (final tool in tools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  static Animal? tryAnimalById(String id) {
    for (final animal in productiveAnimals) {
      if (animal.id == id) return animal;
    }
    for (final animal in petAnimals) {
      if (animal.id == id) return animal;
    }
    return null;
  }

  static Crop? tryCropById(String id) {
    for (final crop in crops) {
      if (crop.id == id) return crop;
    }
    return null;
  }

  /// Use tryCropById when loading player-controlled or saved data.
  static Crop cropById(String id) =>
      tryCropById(id) ?? (throw ArgumentError.value(id, 'id', 'Unknown crop id'));
}
