import '../models/animal.dart';
import '../models/crop.dart';
import '../models/tool_item.dart';

class ShopData {
  static const List<Crop> crops = [
    Crop(id: 'wheat', name: 'القمح', emoji: '🌾', price: 10000, requiredLevel: 1, growSeconds: 10),
    Crop(id: 'corn', name: 'الذرة', emoji: '🌽', price: 25000, requiredLevel: 3, growSeconds: 20),
    Crop(id: 'carrot', name: 'الجزر', emoji: '🥕', price: 57000, requiredLevel: 5, growSeconds: 30),
    Crop(id: 'cucumber', name: 'الخيار', emoji: '🥒', price: 123000, requiredLevel: 7, growSeconds: 40),
    Crop(id: 'tomato', name: 'الطماطم', emoji: '🍅', price: 257000, requiredLevel: 10, growSeconds: 60),
    Crop(id: 'potato', name: 'البطاطس', emoji: '🥔', price: 527000, requiredLevel: 14, growSeconds: 90),
    Crop(id: 'lemon', name: 'الليمون', emoji: '🍋', price: 1300000, requiredLevel: 18, growSeconds: 120),
    Crop(id: 'apple', name: 'التفاح', emoji: '🍎', price: 2680000, requiredLevel: 25, growSeconds: 180),
    Crop(id: 'orange', name: 'البرتقال', emoji: '🍊', price: 5560000, requiredLevel: 30, growSeconds: 240),
    Crop(id: 'grape', name: 'العنب', emoji: '🍇', price: 11320000, requiredLevel: 37, growSeconds: 300),
    Crop(id: 'strawberry', name: 'الفراولة', emoji: '🍓', price: 22950000, requiredLevel: 45, growSeconds: 400),
    Crop(id: 'berry', name: 'التوت', emoji: '🫐', price: 46200000, requiredLevel: 60, growSeconds: 500),
    Crop(id: 'cherry', name: 'الكرز', emoji: '🍒', price: 135000000, requiredLevel: 75, growSeconds: 600),
    Crop(id: 'pineapple', name: 'الأناناس', emoji: '🍍', price: 340000000, requiredLevel: 100, growSeconds: 800),
    Crop(id: 'coconut', name: 'جوز الهند', emoji: '🥥', price: 1000000000, requiredLevel: 120, growSeconds: 1000),
  ];

  static const List<Animal> productiveAnimals = [
    Animal(id: 'chicken', name: 'الدجاج', emoji: '🐔', price: 100000, cycleSeconds: 30),
    Animal(id: 'cow', name: 'البقر', emoji: '🐄', price: 250000, cycleSeconds: 45),
    Animal(id: 'sheep', name: 'الغنم', emoji: '🐑', price: 750000, cycleSeconds: 60),
    Animal(id: 'fish', name: 'السمك', emoji: '🐟', price: 1500000, cycleSeconds: 60),
    Animal(id: 'birds', name: 'الطيور', emoji: '🦜', price: 2000000, cycleSeconds: 60),
    Animal(id: 'bees', name: 'النحل', emoji: '🐝', price: 1000000, cycleSeconds: 45),
  ];

  static const List<Animal> petAnimals = [
    Animal(id: 'cat', name: 'القطط', emoji: '🐱', price: 120000, isProductive: false, petBonusPercent: 1),
    Animal(id: 'dog', name: 'الكلاب', emoji: '🐶', price: 360000, isProductive: false, petBonusPercent: 2),
    Animal(id: 'horse', name: 'الخيول', emoji: '🐴', price: 950000, isProductive: false, petBonusPercent: 4),
  ];

  static const List<ToolItem> tools = [
    ToolItem(id: 'axe', name: 'الفأس', emoji: '🪓', goldPrice: 15, description: 'يزيد سرعة الحصاد 25%'),
    ToolItem(id: 'bucket', name: 'الدلو', emoji: '🪣', goldPrice: 20, description: 'يقلل وقت نمو المحاصيل للنصف'),
    ToolItem(id: 'pickaxe', name: 'المعول', emoji: '⛏️', goldPrice: 30, description: 'يعطي مضاعفة (x2) للحصاد'),
  ];

  static Crop cropById(String id) => crops.firstWhere((c) => c.id == id);
}
