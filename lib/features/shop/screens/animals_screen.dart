import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';

import '../data/shop_data.dart';
import '../widgets/animal_card.dart';
import '../widgets/shop_header.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final ownedProductive = ShopData.productiveAnimals.fold<int>(0, (sum, a) => sum + game.ownedAnimals(a.id));
    final ownedPets = ShopData.petAnimals.fold<int>(0, (sum, a) => sum + game.ownedAnimals(a.id));
    final pending = game.totalPendingAnimalIncome;
    final q = _query.trim().toLowerCase();
    final productive = ShopData.productiveAnimals.where((a) => '${a.name} ${a.id} ${a.emoji}'.toLowerCase().contains(q)).toList();
    final pets = ShopData.petAnimals.where((a) => '${a.name} ${a.id} ${a.emoji}'.toLowerCase().contains(q)).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _BarnSummary(ownedProductive: ownedProductive, ownedPets: ownedPets, pending: pending, feed: game.animalFeed),
        ShopHeader(emoji: '🐮', title: 'سوق الحيوانات', subtitle: 'وسّع مزرعتك بين الحيوانات المنتجة والأليفة', count: ShopData.productiveAnimals.length + ShopData.petAnimals.length),
        ShopSearchField(hint: 'ابحث عن حيوان...', onChanged: (value) => setState(() => _query = value)),
        if (productive.isNotEmpty) ...[
          _SectionLabel(title: '🐄 حيوانات إنتاجية', count: productive.length),
          for (final animal in productive) AnimalCard(key: ValueKey(animal.id), animal: animal),
        ],
        if (pets.isNotEmpty) ...[
          _SectionLabel(title: '🐾 حيوانات أليفة', count: pets.length),
          for (final animal in pets) AnimalCard(key: ValueKey(animal.id), animal: animal),
        ],
        if (productive.isEmpty && pets.isEmpty) ShopEmptyState(query: _query),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)))),
      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE3F5D9), borderRadius: BorderRadius.circular(10)), child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w900))),
    ]),
  );
}


class _BarnSummary extends StatelessWidget {
  const _BarnSummary({required this.ownedProductive, required this.ownedPets, required this.pending, required this.feed});
  final int ownedProductive;
  final int ownedPets;
  final int pending;
  final int feed;

  @override
  Widget build(BuildContext context) => CartoonCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Text('🏡', style: TextStyle(fontSize: 27)), SizedBox(width: 8), Expanded(child: Text('حظيرتك ومزرعة الحيوانات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.dark)))]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _BarnStat(icon: '🐄', label: 'إنتاجية', value: '$ownedProductive')),
        const SizedBox(width: 5),
        Expanded(child: _BarnStat(icon: '🐾', label: 'أليفة', value: '$ownedPets')),
        const SizedBox(width: 5),
        Expanded(child: _BarnStat(icon: '🧺', label: 'جاهز للجمع', value: formatIqd(pending))),
        const SizedBox(width: 5),
        Expanded(child: _BarnStat(icon: '🌾', label: 'العلف', value: '$feed')),
      ]),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: CartoonButton(
        color: AppColors.orange,
        leading: '🌾',
        label: 'شراء كيس علف ×5 — ${formatIqd(GameState.animalFeedPackPrice)}',
        onPressed: () {
          final error = context.read<GameState>().buyAnimalFeed();
          showToast(context, error ?? 'تم شراء 5 وحدات علف', color: error == null ? AppColors.green : AppColors.red);
        },
      )),
      if (pending > 0) ...[
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: CartoonButton(
          color: AppColors.green,
          leading: '🧺',
          label: 'اجمع إنتاج كل الحيوانات',
          onPressed: () {
            final total = context.read<GameState>().collectAllAnimals();
            showToast(context, 'تم جمع ${formatIqd(total)} من الحيوانات', color: AppColors.green);
          },
        )),
      ],
    ]),
  );
}

class _BarnStat extends StatelessWidget {
  const _BarnStat({required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 68),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.gold)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 3),
      FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.dark))),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ]),
  );
}
