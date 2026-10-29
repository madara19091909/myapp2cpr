import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../../shop/data/shop_data.dart';
import '../../decor/data/decor_data.dart';
import '../data/building_data.dart';

class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
      children: [
        CartoonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏗️ مباني المزرعة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.dark)),
              const SizedBox(height: 6),
              const Text(
                'اشترِ مباني دائمة تعطي مكافآت، وافتح المصانع للتصنيع.',
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip('${game.weather.emoji} ${game.weather.name}'),
                  _chip('${game.season.emoji} ${game.season.name}'),
                  _chip('مباني ${game.ownedBuildings.length}/${BuildingData.buildings.length}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('المباني', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...BuildingData.buildings.map((b) => _BuildingTile(building: b)),
        const SizedBox(height: 18),
        const Text('التصنيع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (game.activeCrafts.isNotEmpty) ...[
          CartoonCard(
            color: const Color(0xFFFFF3E0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('قيد التصنيع', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...game.activeCrafts.map((c) {
                  final readyAt = DateTime.tryParse(c['readyAt']?.toString() ?? '');
                  final left = readyAt == null ? 0 : readyAt.difference(DateTime.now()).inSeconds;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${c['emoji'] ?? ''} ${c['name'] ?? ''} ×${c['qty'] ?? 1} — ${left > 0 ? 'باقي ${left}ث' : 'جاهز عند التحديث'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        ...BuildingData.recipes.map((r) => _RecipeTile(recipe: r)),
        const SizedBox(height: 18),
        const Text('الديكور', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...DecorData.items.map((d) => _DecorTile(decor: d)),
        if (game.products.isNotEmpty) ...[

          const SizedBox(height: 18),
          const Text('منتجاتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...game.products.entries.map((e) {
            final price = game.productSalePrice(e.key);
            String name = e.key;
            String emoji = '📦';
            for (final r in BuildingData.recipes) {
              if (r.outputId == e.key) {
                name = r.outputName;
                emoji = r.outputEmoji;
                break;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CartoonCard(
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text('×${e.value} • ${formatIqd(price)} للقطعة', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    CartoonButton(
                      label: 'بيع الكل',
                      height: 42,
                      fontSize: 14,
                      color: AppColors.orange,
                      onPressed: () {
                        final err = context.read<GameState>().sellProduct(e.key, e.value);
                        showToast(context, err ?? 'تم البيع', color: err == null ? AppColors.green : AppColors.red);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  static Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

class _BuildingTile extends StatelessWidget {
  const _BuildingTile({required this.building});
  final BuildingDef building;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final owned = game.hasBuilding(building.id);
    final locked = game.level < building.requiredLevel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartoonCard(
        borderColor: owned ? AppColors.green : AppColors.outline,
        child: Row(
          children: [
            Text(building.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(building.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(building.description, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('مستوى ${building.requiredLevel} • ${formatIqd(building.price)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (owned)
              const Text('✓ مملوك', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900))
            else
              CartoonButton(
                label: locked ? 'مقفل' : 'شراء',
                height: 42,
                fontSize: 14,
                color: locked ? Colors.grey : AppColors.green,
                onPressed: locked
                    ? null
                    : () {
                        final err = context.read<GameState>().buyBuilding(building);
                        showToast(context, err ?? 'تم بناء ${building.name}!', color: err == null ? AppColors.green : AppColors.red);
                      },
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe});
  final RecipeDef recipe;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final hasB = game.hasBuilding(recipe.buildingId);
    final locked = game.level < recipe.requiredLevel || !hasB;
    final crop = ShopData.tryCropById(recipe.inputCropId);
    final inputName = crop?.name ?? recipe.inputCropId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartoonCard(
        child: Row(
          children: [
            Text(recipe.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(
                    '${recipe.inputQty}× $inputName → ${recipe.outputEmoji} ${recipe.outputName}\n${recipe.craftSeconds}ث • يباع بـ ${formatIqd(recipe.outputSellPrice)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            CartoonButton(
              label: locked ? 'مقفل' : 'تصنيع',
              height: 42,
              fontSize: 13,
              color: locked ? Colors.grey : AppColors.orange,
              onPressed: locked
                  ? null
                  : () {
                      final err = context.read<GameState>().startCraft(recipe);
                      showToast(context, err ?? 'بدأ التصنيع', color: err == null ? AppColors.green : AppColors.red);
                    },
            ),
          ],
        ),
      ),
    );
  }
}


class _DecorTile extends StatelessWidget {
  const _DecorTile({required this.decor});
  final DecorItem decor;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final owned = game.hasDecor(decor.id);
    final locked = game.level < decor.requiredLevel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartoonCard(
        borderColor: owned ? AppColors.green : AppColors.outline,
        child: Row(
          children: [
            Text(decor.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(decor.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(decor.description, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  Text('مستوى ${decor.requiredLevel} • ${formatIqd(decor.price)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (owned)
              const Text('✓', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 22))
            else
              CartoonButton(
                label: locked ? 'مقفل' : 'شراء',
                height: 42,
                fontSize: 14,
                color: locked ? Colors.grey : AppColors.purple,
                onPressed: locked
                    ? null
                    : () {
                        final err = context.read<GameState>().buyDecor(decor);
                        showToast(context, err ?? 'تم وضع ${decor.name}!', color: err == null ? AppColors.green : AppColors.red);
                      },
              ),
          ],
        ),
      ),
    );
  }
}
