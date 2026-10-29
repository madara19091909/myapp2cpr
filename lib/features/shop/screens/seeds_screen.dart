import 'package:flutter/material.dart';

import '../data/shop_data.dart';
import '../widgets/crop_card.dart';
import '../widgets/shop_header.dart';

class SeedsScreen extends StatefulWidget {
  const SeedsScreen({super.key});

  @override
  State<SeedsScreen> createState() => _SeedsScreenState();
}

class _SeedsScreenState extends State<SeedsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final crops = ShopData.crops.where((crop) =>
      '${crop.name} ${crop.id} ${crop.emoji}'.toLowerCase().contains(_query.trim().toLowerCase())).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        ShopHeader(emoji: '🌱', title: 'متجر البذور', subtitle: 'ازرع بذكاء، وراقب وقت النمو قبل الشراء', count: ShopData.crops.length),
        ShopSearchField(hint: 'ابحث عن محصول...', onChanged: (value) => setState(() => _query = value)),
        if (crops.isEmpty) ShopEmptyState(query: _query)
        else for (final crop in crops) CropCard(key: ValueKey(crop.id), crop: crop),
      ],
    );
  }
}
