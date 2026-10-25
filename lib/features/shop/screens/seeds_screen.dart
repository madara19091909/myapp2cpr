import 'package:flutter/material.dart';

import '../data/shop_data.dart';
import '../widgets/crop_card.dart';
import '../widgets/emoji_badge.dart';

class SeedsScreen extends StatelessWidget {
  const SeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ScreenTitle('🌱 متجر البذور'),
        for (final crop in ShopData.crops) CropCard(crop: crop),
      ],
    );
  }
}
