import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../../shop/data/shop_data.dart';
import '../../shop/models/crop.dart';

/// مخزن اللاعب: البذور والمحاصيل المحصودة والحيوانات والأدوات والعلف وماء الزراعة.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final stored = ShopData.crops.where((crop) => game.storedCrop(crop.id) > 0).toList();
    final seeds = ShopData.crops.where((crop) => game.ownedSeeds(crop.id) > 0).toList();
    final animals = [...ShopData.productiveAnimals, ...ShopData.petAnimals]
        .where((animal) => game.ownedAnimals(animal.id) > 0).toList();
    final tools = ShopData.tools.where((tool) => game.hasTool(tool.id)).toList();

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF7DD), Color(0xFFFFE6B3)],
      )),
      child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 28), children: [
        const Text('🎒 مخزن المزرعة', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.dark)),
        const SizedBox(height: 4),
        const Text('كل ممتلكاتك بمكان واحد — احصد وخزّن وبعدين بيع وقت ما تريد', textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SummaryTile(emoji: '🌾', label: 'محاصيل', value: formatNumber(game.totalStoredCrops))),
          const SizedBox(width: 7),
          Expanded(child: _SummaryTile(emoji: '🌱', label: 'بذور', value: formatNumber(game.totalSeedCount))),
          const SizedBox(width: 7),
          Expanded(child: _SummaryTile(emoji: '🐄', label: 'حيوانات', value: formatNumber(game.totalAnimalCount))),
        ]),
        if (game.products.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionHeader(emoji: '🏭', title: 'منتجات مصنّعة', trailing: '${game.products.length} نوع'),
          ...game.products.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: CartoonCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Expanded(child: Text('${e.key} ×${e.value} • ${formatIqd(game.productSalePrice(e.key))}',
                  style: const TextStyle(fontWeight: FontWeight.w800))),
                TextButton(
                  onPressed: () {
                    final err = context.read<GameState>().sellProduct(e.key, e.value);
                    showToast(context, err ?? 'تم البيع', color: err == null ? AppColors.green : AppColors.red);
                  },
                  child: const Text('بيع الكل', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          )),
        ],
        const SizedBox(height: 14),
        _SectionHeader(emoji: '🌾', title: 'المحاصيل المحصودة', trailing: '${game.totalStoredCrops} قطعة'),
        if (stored.isEmpty)
          const _EmptyInventory(text: 'ما عندك محاصيل مخزونة حالياً. احصد من المزرعة حتى تظهر هنا.')
        else ...[
          Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () {
                final count = game.totalStoredCrops;
                final error = context.read<GameState>().sellAllHarvestedCrops();
                showToast(context, error ?? 'تم بيع $count محصول وإضافة الأرباح لرصيدك 💰',
                  color: error == null ? AppColors.green : AppColors.red);
              },
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('بيع كل المحاصيل المخزونة', style: TextStyle(fontWeight: FontWeight.w900)),
            ))),
          ...stored.map((crop) => _StoredCropCard(crop: crop, quantity: game.storedCrop(crop.id))),
        ],
        const SizedBox(height: 14),
        _SectionHeader(emoji: '🌱', title: 'مخزون البذور', trailing: '${seeds.length} أنواع'),
        if (seeds.isEmpty)
          const _EmptyInventory(text: 'ما عندك بذور. تقدر تشتري بذور من تبويب البذور.')
        else
          CartoonCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: Column(children: [
            for (var i = 0; i < seeds.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _SimpleStockRow(emoji: seeds[i].emoji, title: seeds[i].name,
                subtitle: 'تحتاج بذرة واحدة لكل مساحة زراعة', quantity: game.ownedSeeds(seeds[i].id)),
            ],
          ])),
        const SizedBox(height: 14),
        _SectionHeader(emoji: '🐾', title: 'حيوانات المزرعة', trailing: '${animals.length} أنواع'),
        if (animals.isEmpty)
          const _EmptyInventory(text: 'ما عندك حيوانات حالياً. تقدر تشتريها من تبويب الحيوانات.')
        else
          CartoonCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: Column(children: [
            for (var i = 0; i < animals.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _SimpleStockRow(emoji: animals[i].emoji, title: animals[i].name,
                subtitle: animals[i].isProductive ? 'حيوان إنتاجي' : 'حيوان أليف • مكافأة +${animals[i].petBonusPercent}%',
                quantity: game.ownedAnimals(animals[i].id)),
            ],
          ])),
        const SizedBox(height: 14),
        _SectionHeader(emoji: '🧰', title: 'الأدوات المملوكة', trailing: '${tools.length}/${ShopData.tools.length}'),
        if (tools.isEmpty)
          const _EmptyInventory(text: 'ما اشتريت أدوات بعد. الأدوات تظهر هنا بعد شرائها من تبويب الأدوات.')
        else
          CartoonCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: Column(children: [
            for (var i = 0; i < tools.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _SimpleStockRow(emoji: tools[i].emoji, title: tools[i].name,
                subtitle: tools[i].description, quantity: 1, quantityLabel: 'مملوك'),
            ],
          ])),
        const SizedBox(height: 14),
        _SectionHeader(emoji: '🌿', title: 'علف الحيوانات', trailing: '${game.animalFeed} وحدة'),
        CartoonCard(child: Row(children: [
          Container(width: 50, height: 50, alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(15)),
            child: const Text('🌿', style: TextStyle(fontSize: 28))),
          const SizedBox(width: 12),
          const Expanded(child: Text('كل وحدة علف تكفي حيواناً واحداً عند إطعام القطيع من صفحة الحيوانات.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4))),
          Text('${game.animalFeed}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.dark)),
        ])),
        const SizedBox(height: 14),
        _SectionHeader(emoji: '💧', title: 'ماء الزراعة', trailing: '${game.waterUnits} وحدة'),
        CartoonCard(child: Row(children: [
          Container(width: 50, height: 50, alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.water_drop, size: 30, color: Color(0xFF0284C7))),
          const SizedBox(width: 12),
          const Expanded(child: Text('كل وحدة تسقي محصولاً مرة واحدة وتقلل وقت نموه بنسبة 25%.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4))),
          Text('${game.waterUnits}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.dark)),
        ])),
      ]),
    );
  }
}

class _StoredCropCard extends StatelessWidget {
  const _StoredCropCard({required this.crop, required this.quantity});
  final Crop crop;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final unitPrice = game.marketSalePrice(crop);
    final total = unitPrice * quantity;
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2))]),
      child: Row(children: [
        Container(width: 48, height: 48, alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
          child: Text(crop.emoji, style: const TextStyle(fontSize: 29))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.dark)),
          Text('الكمية: $quantity • ${formatIqd(unitPrice)} للقطعة', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text('قيمة السوق اليوم: ${formatIqd(total)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.green)),
        ])),
        const SizedBox(width: 6),
        Column(children: [
          IconButton.filled(tooltip: 'بيع قطعة واحدة', visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            onPressed: () {
              final error = context.read<GameState>().sellHarvestedCrop(crop, 1);
              showToast(context, error ?? 'تم بيع قطعة من ${crop.name}', color: error == null ? AppColors.green : AppColors.red);
            }, icon: const Icon(Icons.sell_rounded, size: 18)),
          const Text('بيع 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.dark)),
        ]),
      ]),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.emoji, required this.label, required this.value});
  final String emoji;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.outline)),
    child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.dark)),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: AppColors.muted))]));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.emoji, required this.title, required this.trailing});
  final String emoji;
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 21)), const SizedBox(width: 7),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.dark))),
      Text(trailing, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted))]));
}

class _SimpleStockRow extends StatelessWidget {
  const _SimpleStockRow({required this.emoji, required this.title, required this.subtitle, required this.quantity, this.quantityLabel});
  final String emoji;
  final String title;
  final String subtitle;
  final int quantity;
  final String? quantityLabel;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.dark)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ])), const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
        child: Text(quantityLabel ?? '×$quantity', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green))),
    ]));
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => CartoonCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    child: Column(children: [const Text('🧺', style: TextStyle(fontSize: 34)), const SizedBox(height: 7),
      Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4))])));
}
