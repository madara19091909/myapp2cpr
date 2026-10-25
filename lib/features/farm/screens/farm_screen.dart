import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ticker_builder.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../../shop/data/shop_data.dart';
import '../../shop/models/animal.dart';
import '../widgets/plot_tile.dart';
import '../widgets/seed_picker.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key});

  void _onTap(BuildContext context, int i) {
    final g = context.read<GameState>();
    final plot = g.plots[i];
    final now = DateTime.now();
    if (plot.isEmpty) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => SeedPicker(plotIndex: i),
      );
    } else if (plot.isReady(now)) {
      final r = g.harvest(i);
      if (r != null) {
        final extra = r.levelsGained > 0
            ? '\n🎉 ارتقيت للمستوى ${g.level}! +${r.levelsGained * GameState.levelUpGoldReward} 🪙'
            : '';
        showToast(context, '+${formatIqd(r.income)}  •  +${r.xp} XP$extra', color: AppColors.green);
      }
    } else {
      showToast(context, 'المحصول لم ينضج بعد ⏳');
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final wide = MediaQuery.of(context).orientation == Orientation.landscape;
    final count = wide ? 4 : 3;
    final plots = TickerBuilder(
      builder: (context, now) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: g.plots.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: wide ? 1.18 : 1,
        ),
        itemBuilder: (context, i) => PlotTile(
          plot: g.plots[i], now: now, onTap: () => _onTap(context, i),
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFB7E6F7), Color(0xFFDDF1B0), Color(0xFF79B94A), Color(0xFF477E32)],
          stops: [0, .18, .19, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
            child: Row(children: [
              const Text('🌤️', style: TextStyle(fontSize: 25)),
              const SizedBox(width: 8),
              const Expanded(child: Text('مزرعتي الجميلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.dark))),
              _Badge('⚡ ×${(1 / g.speedFactor).toStringAsFixed(1)}'),
              const SizedBox(width: 6),
              _Badge('🌾 ×${g.yieldMultiplier}'),
              const SizedBox(width: 6),
              _Badge('🐾 +${g.petBonusPercent}%'),
            ]),
          ),
          Expanded(
            child: wide
              ? Row(children: [
                  Expanded(flex: 6, child: plots),
                  Expanded(flex: 4, child: _AnimalPasture(animals: _ownedAnimals(g.animals))),
                ])
              : Column(children: [
                  SizedBox(height: 94, child: _AnimalPasture(animals: _ownedAnimals(g.animals))),
                  Expanded(child: plots),
                ]),
          ),
        ]),
      ),
    );
  }

  List<Animal> _ownedAnimals(Map<String, int> owned) => [
    for (final animal in [...ShopData.productiveAnimals, ...ShopData.petAnimals])
      if ((owned[animal.id] ?? 0) > 0) animal,
  ];
}

class _AnimalPasture extends StatefulWidget {
  const _AnimalPasture({required this.animals});
  final List<Animal> animals;

  @override
  State<_AnimalPasture> createState() => _AnimalPastureState();
}

class _AnimalPastureState extends State<_AnimalPasture> with SingleTickerProviderStateMixin {
  late final AnimationController _walk = AnimationController(
    vsync: this, duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() { _walk.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 4, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFB9DE83), Color(0xFF75B64A), Color(0xFF4C8A36)]),
        border: Border.all(color: const Color(0xFF386B2A), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Stack(children: [
        Positioned(top: 8, left: 12, child: Text('🌳', style: TextStyle(fontSize: 25))),
        Positioned(bottom: 8, right: 12, child: Text('🌼  🌱  🌼', style: TextStyle(fontSize: 15))),
        Positioned(top: 8, right: 12, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(12)),
          child: Text(widget.animals.isEmpty ? 'حظيرة الحيوانات' : 'حيواناتي • ${widget.animals.length} أنواع',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.dark)),
        )),
        if (widget.animals.isEmpty)
          const Center(child: Text('اشترِ حيواناً من السوق ليعيش هنا 🐄', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)))
        else
          AnimatedBuilder(animation: _walk, builder: (context, _) {
            final shift = (_walk.value - .5) * 22;
            return Align(
              alignment: Alignment(-.78 + _walk.value * 1.35, .35),
              child: Transform.translate(
                offset: Offset(shift, 0),
                child: Wrap(spacing: 12, children: widget.animals.take(5).map((a) => _WalkingAnimal(animal: a)).toList()),
              ),
            );
          }),
      ]),
    );
  }
}

class _WalkingAnimal extends StatefulWidget {
  const _WalkingAnimal({required this.animal});
  final Animal animal;
  @override
  State<_WalkingAnimal> createState() => _WalkingAnimalState();
}
class _WalkingAnimalState extends State<_WalkingAnimal> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 480))..repeat(reverse: true);
  @override
  void dispose() { _bounce.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _bounce, builder: (context, child) => Transform.translate(
    offset: Offset(0, -_bounce.value * 3), child: child,
  ), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(widget.animal.emoji, style: const TextStyle(fontSize: 29)),
    Container(width: 22, height: 5, decoration: BoxDecoration(color: Colors.black.withOpacity(.2), borderRadius: BorderRadius.circular(8))),
  ]));
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.soilDark, width: 1.5), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 2, offset: Offset(0, 1))]),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.dark)),
  );
}
