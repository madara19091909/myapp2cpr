import '../models/animal.dart';
import '../models/crop.dart';
import '../models/tool_item.dart';

class ShopData {
  static const List<Crop> crops = [
    Crop(id: 'wheat', name: 'القمح', emoji: '🌾', price: 8000, requiredLevel: 1, growSeconds: 90),
    Crop(id: 'lettuce', name: 'الخس', emoji: '🥬', price: 14000, requiredLevel: 2, growSeconds: 120),
    Crop(id: 'corn', name: 'الذرة', emoji: '🌽', price: 22000, requiredLevel: 3, growSeconds: 150),
    Crop(id: 'onion', name: 'البصل', emoji: '🧅', price: 32000, requiredLevel: 4, growSeconds: 180),
    Crop(id: 'carrot', name: 'الجزر', emoji: '🥕', price: 48000, requiredLevel: 5, growSeconds: 240),
    Crop(id: 'pepper', name: 'الفلفل', emoji: '🫑', price: 70000, requiredLevel: 7, growSeconds: 280),
    Crop(id: 'cucumber', name: 'الخيار', emoji: '🥒', price: 95000, requiredLevel: 8, growSeconds: 320),
    Crop(id: 'tomato', name: 'الطماطم', emoji: '🍅', price: 190000, requiredLevel: 11, growSeconds: 420),
    Crop(id: 'eggplant', name: 'الباذنجان', emoji: '🍆', price: 260000, requiredLevel: 13, growSeconds: 480),
    Crop(id: 'potato', name: 'البطاطس', emoji: '🥔', price: 380000, requiredLevel: 15, growSeconds: 540),
    Crop(id: 'lemon', name: 'الليمون', emoji: '🍋', price: 720000, requiredLevel: 19, growSeconds: 720),
    Crop(id: 'apple', name: 'التفاح', emoji: '🍎', price: 1400000, requiredLevel: 24, growSeconds: 900),
    Crop(id: 'peach', name: 'الخوخ', emoji: '🍑', price: 2000000, requiredLevel: 27, growSeconds: 1020),
    Crop(id: 'orange', name: 'البرتقال', emoji: '🍊', price: 2800000, requiredLevel: 30, growSeconds: 1200),
    Crop(id: 'grape', name: 'العنب', emoji: '🍇', price: 5200000, requiredLevel: 36, growSeconds: 1500),
    Crop(id: 'watermelon', name: 'البطيخ', emoji: '🍉', price: 7000000, requiredLevel: 40, growSeconds: 1680),
    Crop(id: 'strawberry', name: 'الفراولة', emoji: '🍓', price: 9500000, requiredLevel: 43, growSeconds: 1800),
    Crop(id: 'berry', name: 'التوت', emoji: '🫐', price: 17000000, requiredLevel: 50, growSeconds: 2100),
    Crop(id: 'cherry', name: 'الكرز', emoji: '🍒', price: 32000000, requiredLevel: 58, growSeconds: 2700),
    Crop(id: 'pineapple', name: 'الأناناس', emoji: '🍍', price: 60000000, requiredLevel: 68, growSeconds: 3300),
    Crop(id: 'coconut', name: 'جوز الهند', emoji: '🥥', price: 110000000, requiredLevel: 80, growSeconds: 4200),
    Crop(id: 'mango', name: 'المانجو', emoji: '🥭', price: 200000000, requiredLevel: 95, growSeconds: 5400),
  ];

  static const List<Animal> productiveAnimals = [
    Animal(id: 'chicken', name: 'الدجاج', emoji: '🐔', price: 80000, cycleSeconds: 300),
    Animal(id: 'rabbit', name: 'الأرانب', emoji: '🐰', price: 140000, cycleSeconds: 360),
    Animal(id: 'cow', name: 'البقر', emoji: '🐄', price: 220000, cycleSeconds: 480),
    Animal(id: 'goat', name: 'الماعز', emoji: '🐐', price: 340000, cycleSeconds: 540),
    Animal(id: 'sheep', name: 'الغنم', emoji: '🐑', price: 550000, cycleSeconds: 720),
    Animal(id: 'bees', name: 'النحل', emoji: '🐝', price: 700000, cycleSeconds: 600),
    Animal(id: 'fish', name: 'السمك', emoji: '🐟', price: 1100000, cycleSeconds: 900),
    Animal(id: 'birds', name: 'الطيور', emoji: '🦜', price: 1800000, cycleSeconds: 1080),
    Animal(id: 'camel', name: 'الجمال', emoji: '🐪', price: 3200000, cycleSeconds: 1500),
  ];

  static const List<Animal> petAnimals = [
    Animal(id: 'cat', name: 'القطط', emoji: '🐱', price: 100000, isProductive: false, petBonusPercent: 1),
    Animal(id: 'dog', name: 'الكلاب', emoji: '🐶', price: 280000, isProductive: false, petBonusPercent: 2),
    Animal(id: 'horse', name: 'الخيول', emoji: '🐴', price: 750000, isProductive: false, petBonusPercent: 4),
    Animal(id: 'peacock', name: 'الطاووس', emoji: '🦚', price: 1500000, isProductive: false, petBonusPercent: 6),
  ];

  static const List<ToolItem> tools = [
    ToolItem(id: 'axe', name: 'الفأس', emoji: '🪓', goldPrice: 18, description: 'يقلل وقت نمو المحاصيل بنسبة 15%'),
    ToolItem(id: 'bucket', name: 'الدلو', emoji: '🪣', goldPrice: 28, description: 'يقلل وقت نمو المحاصيل بنسبة 25% بشكل دائم'),
    ToolItem(id: 'pickaxe', name: 'المعول', emoji: '⛏️', goldPrice: 40, description: 'يضاعف كمية المحصول عند الحصاد (×2) بشكل دائم'),
    ToolItem(id: 'boots', name: 'حذاء المزارع', emoji: '🥾', goldPrice: 22, description: 'يزيد خبرة الحصاد بنسبة 15%'),
    ToolItem(id: 'hat', name: 'قبعة الشمس', emoji: '👒', goldPrice: 15, description: 'يقلل تأثير الطقس السيئ على النمو'),
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
