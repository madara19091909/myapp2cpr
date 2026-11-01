import '../models/animal.dart';
import '../models/crop.dart';
import '../models/tool_item.dart';

class ShopData {
  /// أسعار البذور والحيوانات مطابقة للقائمة المعتمدة.
  /// يبدأ نمو القمح بخمس دقائق، ويزيد خمس دقائق مع كل محصول تالٍ.
  static const List<Crop> crops = [
    Crop(id: 'wheat', name: 'القمح', emoji: '🌾', price: 250, requiredLevel: 1, growSeconds: 300),
    Crop(id: 'lettuce', name: 'الخس', emoji: '🥬', price: 400, requiredLevel: 2, growSeconds: 600),
    Crop(id: 'corn', name: 'الذرة', emoji: '🌽', price: 600, requiredLevel: 3, growSeconds: 900),
    Crop(id: 'onion', name: 'البصل', emoji: '🧅', price: 800, requiredLevel: 4, growSeconds: 1200),
    Crop(id: 'carrot', name: 'الجزر', emoji: '🥕', price: 1000, requiredLevel: 5, growSeconds: 1500),
    Crop(id: 'pepper', name: 'الفلفل', emoji: '🫑', price: 1500, requiredLevel: 7, growSeconds: 1800),
    Crop(id: 'cucumber', name: 'الخيار', emoji: '🥒', price: 2000, requiredLevel: 8, growSeconds: 2100),
    Crop(id: 'tomato', name: 'الطماطم', emoji: '🍅', price: 2500, requiredLevel: 10, growSeconds: 2400),
    Crop(id: 'eggplant', name: 'الباذنجان', emoji: '🍆', price: 3200, requiredLevel: 12, growSeconds: 2700),
    Crop(id: 'potato', name: 'البطاطس', emoji: '🥔', price: 4000, requiredLevel: 14, growSeconds: 3000),
    Crop(id: 'lemon', name: 'الليمون', emoji: '🍋', price: 5500, requiredLevel: 17, growSeconds: 3300),
    Crop(id: 'apple', name: 'التفاح', emoji: '🍎', price: 7000, requiredLevel: 20, growSeconds: 3600),
    Crop(id: 'peach', name: 'الخوخ', emoji: '🍑', price: 9000, requiredLevel: 24, growSeconds: 3900),
    Crop(id: 'orange', name: 'البرتقال', emoji: '🍊', price: 11000, requiredLevel: 28, growSeconds: 4200),
    Crop(id: 'grape', name: 'العنب', emoji: '🍇', price: 14000, requiredLevel: 32, growSeconds: 4500),
    Crop(id: 'watermelon', name: 'البطيخ', emoji: '🍉', price: 18000, requiredLevel: 36, growSeconds: 4800),
    Crop(id: 'strawberry', name: 'الفراولة', emoji: '🍓', price: 23000, requiredLevel: 40, growSeconds: 5100),
    Crop(id: 'berry', name: 'التوت', emoji: '🫐', price: 30000, requiredLevel: 45, growSeconds: 5400),
    Crop(id: 'cherry', name: 'الكرز', emoji: '🍒', price: 40000, requiredLevel: 50, growSeconds: 5700),
    Crop(id: 'pineapple', name: 'الأناناس', emoji: '🍍', price: 55000, requiredLevel: 58, growSeconds: 6000),
    Crop(id: 'coconut', name: 'جوز الهند', emoji: '🥥', price: 80000, requiredLevel: 66, growSeconds: 6300),
    Crop(id: 'mango', name: 'المانجو', emoji: '🥭', price: 120000, requiredLevel: 75, growSeconds: 6600),
  ];

  static const List<Animal> productiveAnimals = [
    Animal(id: 'chicken', name: 'الدجاج', emoji: '🐔', price: 15000, cycleSeconds: 1500),
    Animal(id: 'rabbit', name: 'الأرانب', emoji: '🐰', price: 25000, cycleSeconds: 1800),
    Animal(id: 'bees', name: 'النحل', emoji: '🐝', price: 40000, cycleSeconds: 2700),
    Animal(id: 'birds', name: 'الطيور', emoji: '🦜', price: 65000, cycleSeconds: 4200),
    Animal(id: 'fish', name: 'السمك', emoji: '🐟', price: 100000, cycleSeconds: 3600),
    Animal(id: 'sheep', name: 'الغنم', emoji: '🐑', price: 180000, cycleSeconds: 3000),
    Animal(id: 'goat', name: 'الماعز', emoji: '🐐', price: 250000, cycleSeconds: 2700),
    Animal(id: 'cow', name: 'البقر', emoji: '🐄', price: 400000, cycleSeconds: 2400),
    Animal(id: 'camel', name: 'الجمال', emoji: '🐪', price: 750000, cycleSeconds: 5400),
  ];

  static const List<Animal> petAnimals = [
    Animal(id: 'cat', name: 'القطط', emoji: '🐱', price: 20000, isProductive: false, petBonusPercent: 1),
    Animal(id: 'dog', name: 'الكلاب', emoji: '🐶', price: 50000, isProductive: false, petBonusPercent: 2),
    Animal(id: 'peacock', name: 'الطاووس', emoji: '🦚', price: 120000, isProductive: false, petBonusPercent: 3),
    Animal(id: 'horse', name: 'الخيول', emoji: '🐴', price: 300000, isProductive: false, petBonusPercent: 4),
  ];

  static const List<ToolItem> tools = [
    ToolItem(id: 'axe', name: 'الفأس', emoji: '🪓', goldPrice: 25, description: 'يقلل وقت نمو المحاصيل بنسبة 12%'),
    ToolItem(id: 'bucket', name: 'الدلو', emoji: '🪣', goldPrice: 40, description: 'يقلل وقت نمو المحاصيل بنسبة 20% بشكل دائم'),
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
