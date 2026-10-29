import '../models/animal.dart';
import '../models/crop.dart';
import '../models/tool_item.dart';

class ShopData {
  /// أوقات نمو أطول وأسعار بذور أعلى نسبياً — تقدم بطيء محسوب.
  static const List<Crop> crops = [
    Crop(id: 'wheat', name: 'القمح', emoji: '🌾', price: 7500, requiredLevel: 1, growSeconds: 1200),
    Crop(id: 'lettuce', name: 'الخس', emoji: '🥬', price: 14000, requiredLevel: 2, growSeconds: 1500),
    Crop(id: 'corn', name: 'الذرة', emoji: '🌽', price: 22000, requiredLevel: 3, growSeconds: 1800),
    Crop(id: 'onion', name: 'البصل', emoji: '🧅', price: 35000, requiredLevel: 4, growSeconds: 2400),
    Crop(id: 'carrot', name: 'الجزر', emoji: '🥕', price: 52000, requiredLevel: 5, growSeconds: 3000),
    Crop(id: 'pepper', name: 'الفلفل', emoji: '🫑', price: 80000, requiredLevel: 7, growSeconds: 3600),
    Crop(id: 'cucumber', name: 'الخيار', emoji: '🥒', price: 110000, requiredLevel: 8, growSeconds: 4200),
    Crop(id: 'tomato', name: 'الطماطم', emoji: '🍅', price: 200000, requiredLevel: 11, growSeconds: 5400),
    Crop(id: 'eggplant', name: 'الباذنجان', emoji: '🍆', price: 280000, requiredLevel: 13, growSeconds: 6600),
    Crop(id: 'potato', name: 'البطاطس', emoji: '🥔', price: 400000, requiredLevel: 15, growSeconds: 7800),
    Crop(id: 'lemon', name: 'الليمون', emoji: '🍋', price: 720000, requiredLevel: 19, growSeconds: 9600),
    Crop(id: 'apple', name: 'التفاح', emoji: '🍎', price: 1300000, requiredLevel: 24, growSeconds: 12000),
    Crop(id: 'peach', name: 'الخوخ', emoji: '🍑', price: 2000000, requiredLevel: 27, growSeconds: 14400),
    Crop(id: 'orange', name: 'البرتقال', emoji: '🍊', price: 3000000, requiredLevel: 30, growSeconds: 16800),
    Crop(id: 'grape', name: 'العنب', emoji: '🍇', price: 5000000, requiredLevel: 36, growSeconds: 21600),
    Crop(id: 'watermelon', name: 'البطيخ', emoji: '🍉', price: 7500000, requiredLevel: 40, growSeconds: 25200),
    Crop(id: 'strawberry', name: 'الفراولة', emoji: '🍓', price: 10000000, requiredLevel: 43, growSeconds: 28800),
    Crop(id: 'berry', name: 'التوت', emoji: '🫐', price: 16000000, requiredLevel: 50, growSeconds: 36000),
    Crop(id: 'cherry', name: 'الكرز', emoji: '🍒', price: 30000000, requiredLevel: 58, growSeconds: 43200),
    Crop(id: 'pineapple', name: 'الأناناس', emoji: '🍍', price: 55000000, requiredLevel: 68, growSeconds: 54000),
    Crop(id: 'coconut', name: 'جوز الهند', emoji: '🥥', price: 95000000, requiredLevel: 80, growSeconds: 64800),
    Crop(id: 'mango', name: 'المانجو', emoji: '🥭', price: 160000000, requiredLevel: 95, growSeconds: 86400),
  ];

  static const List<Animal> productiveAnimals = [
    Animal(id: 'chicken', name: 'الدجاج', emoji: '🐔', price: 150000, cycleSeconds: 1500),
    Animal(id: 'rabbit', name: 'الأرانب', emoji: '🐰', price: 250000, cycleSeconds: 1800),
    Animal(id: 'cow', name: 'البقر', emoji: '🐄', price: 450000, cycleSeconds: 2400),
    Animal(id: 'goat', name: 'الماعز', emoji: '🐐', price: 600000, cycleSeconds: 2700),
    Animal(id: 'sheep', name: 'الغنم', emoji: '🐑', price: 850000, cycleSeconds: 3000),
    Animal(id: 'bees', name: 'النحل', emoji: '🐝', price: 1100000, cycleSeconds: 2700),
    Animal(id: 'fish', name: 'السمك', emoji: '🐟', price: 1800000, cycleSeconds: 3600),
    Animal(id: 'birds', name: 'الطيور', emoji: '🦜', price: 2800000, cycleSeconds: 4200),
    Animal(id: 'camel', name: 'الجمال', emoji: '🐪', price: 5000000, cycleSeconds: 5400),
  ];

  static const List<Animal> petAnimals = [
    Animal(id: 'cat', name: 'القطط', emoji: '🐱', price: 150000, isProductive: false, petBonusPercent: 1),
    Animal(id: 'dog', name: 'الكلاب', emoji: '🐶', price: 350000, isProductive: false, petBonusPercent: 2),
    Animal(id: 'horse', name: 'الخيول', emoji: '🐴', price: 900000, isProductive: false, petBonusPercent: 3),
    Animal(id: 'peacock', name: 'الطاووس', emoji: '🦚', price: 1800000, isProductive: false, petBonusPercent: 4),
  ];

  static const List<ToolItem> tools = [
    ToolItem(id: 'axe', name: 'الفأس', emoji: '🪓', goldPrice: 25, description: 'يقلل وقت نمو المحاصيل بنسبة 12%'),
    ToolItem(id: 'bucket', name: 'الدلو', emoji: '🪣', goldPrice: 40, description: 'يقلل وقت نمو المحاصيل بنسبة 20% بشكل دائم'),
    ToolItem(id: 'pickaxe', name: 'المعول', emoji: '⛏️', goldPrice: 55, description: 'يضاعف كمية المحصول عند الحصاد (×2) بشكل دائم'),
    ToolItem(id: 'boots', name: 'حذاء المزارع', emoji: '🥾', goldPrice: 30, description: 'يزيد خبرة الحصاد بنسبة 10%'),
    ToolItem(id: 'hat', name: 'قبعة الشمس', emoji: '👒', goldPrice: 20, description: 'يقلل تأثير الطقس السيئ على النمو'),
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

  static Crop cropById(String id) =>
      tryCropById(id) ?? (throw ArgumentError.value(id, 'id', 'Unknown crop id'));
}
