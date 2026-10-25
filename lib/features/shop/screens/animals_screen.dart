import 'package:flutter/material.dart';

import '../data/shop_data.dart';
import '../widgets/animal_card.dart';
import '../widgets/emoji_badge.dart';

class AnimalsScreen extends StatelessWidget {
  const AnimalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ScreenTitle('🐄 الحيوانات الإنتاجية'),
        for (final a in ShopData.productiveAnimals) AnimalCard(animal: a),
        const SizedBox(height: 8),
        const ScreenTitle('🐾 الحيوانات الأليفة'),
        for (final a in ShopData.petAnimals) AnimalCard(animal: a),
      ],
    );
  }
}
