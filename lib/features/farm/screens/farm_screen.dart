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

    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _PixelFarmGroundPainter()),
        SafeArea(
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
      ],
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
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFB9DE83), Color(0xFF75B64A), Color(0xFF4C8A36)]),
        border: Border.all(color: const Color(0xFF386B2A), width: 3),
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


/// Procedural pixel-art farm backdrop. Gameplay tiles remain real Flutter widgets
/// above this canvas, so planting and harvesting continue to work normally.
class _PixelFarmGroundPainter extends CustomPainter {
  const _PixelFarmGroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    final tile = (size.width / 54).clamp(10.0, 24.0).toDouble();
    final colors = <Color>[
      const Color(0xFF83B94F), const Color(0xFF8CC257),
      const Color(0xFF79AE48), const Color(0xFF92C75D),
    ];
    for (var y = 0; y < size.height; y += tile.round()) {
      for (var x = 0; x < size.width; x += tile.round()) {
        final n = ((x ~/ tile.round()) * 7 + (y ~/ tile.round()) * 13) % colors.length;
        p.color = colors[n];
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), tile, tile), p);
        if ((x ~/ tile.round() + y ~/ tile.round()) % 5 == 0) {
          p.color = const Color(0xFF6FA342);
          canvas.drawRect(Rect.fromLTWH(x.toDouble() + tile * .28, y.toDouble() + tile * .3, tile * .18, tile * .18), p);
        }
      }
    }

    // Winding dirt lane.
    p.color = const Color(0xFFC99A5C);
    final path = Path()
      ..moveTo(size.width * .48, size.height * .05)
      ..lineTo(size.width * .57, size.height * .05)
      ..lineTo(size.width * .55, size.height * .34)
      ..lineTo(size.width * .64, size.height * .54)
      ..lineTo(size.width * .56, size.height * .78)
      ..lineTo(size.width * .61, size.height)
      ..lineTo(size.width * .43, size.height)
      ..lineTo(size.width * .48, size.height * .77)
      ..lineTo(size.width * .52, size.height * .55)
      ..lineTo(size.width * .44, size.height * .34)
      ..close();
    canvas.drawPath(path, p);
    p.color = const Color(0xFFAD7A45);
    for (var i = 0; i < 18; i++) {
      final x = size.width * (.46 + (i % 4) * .035);
      final y = size.height * (i / 18);
      canvas.drawRect(Rect.fromLTWH(x, y, tile * .38, tile * .18), p);
    }

    // Small pond at the lower-right.
    final pond = Rect.fromLTWH(size.width * .72, size.height * .73, size.width * .21, size.height * .19);
    p.color = const Color(0xFF526C45);
    canvas.drawRect(pond.inflate(tile * .22), p);
    p.color = const Color(0xFF378CC1);
    canvas.drawRect(pond, p);
    p.color = const Color(0xFF65C8E6);
    for (var i = 0; i < 7; i++) {
      canvas.drawRect(Rect.fromLTWH(pond.left + tile * (.5 + i * .65), pond.top + tile * (i.isEven ? .45 : 1.25), tile * .55, tile * .13), p);
    }

    // Crop beds on the left, with individual rows and tiny seedlings.
    final beds = [
      Rect.fromLTWH(size.width * .035, size.height * .18, size.width * .19, size.height * .2),
      Rect.fromLTWH(size.width * .035, size.height * .42, size.width * .19, size.height * .2),
    ];
    for (var b = 0; b < beds.length; b++) {
      p.color = const Color(0xFF68452E);
      canvas.drawRect(beds[b], p);
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 8; col++) {
          final x = beds[b].left + tile * (.18 + col * .65);
          final y = beds[b].top + tile * (.18 + row * .62);
          p.color = (row + col + b).isEven ? const Color(0xFF5B963A) : const Color(0xFF77B743);
          canvas.drawRect(Rect.fromLTWH(x, y, tile * .28, tile * .42), p);
          p.color = const Color(0xFFB9D64F);
          canvas.drawRect(Rect.fromLTWH(x - tile * .1, y + tile * .12, tile * .48, tile * .12), p);
        }
      }
    }

    // Red barn and pale farmhouse, deliberately blocky like pixel sprites.
    _building(canvas, p, Rect.fromLTWH(size.width * .68, size.height * .08, size.width * .22, size.height * .24),
      const Color(0xFFB94F3C), const Color(0xFF3B526A));
    _building(canvas, p, Rect.fromLTWH(size.width * .29, size.height * .08, size.width * .19, size.height * .18),
      const Color(0xFFE6D7A9), const Color(0xFFB94F3C));

    // Fence segments around the perimeter.
    p.color = const Color(0xFF65432C);
    final fenceY = size.height * .94;
    canvas.drawRect(Rect.fromLTWH(size.width * .025, fenceY, size.width * .95, tile * .18), p);
    canvas.drawRect(Rect.fromLTWH(size.width * .025, fenceY + tile * .48, size.width * .95, tile * .18), p);
    for (var i = 0; i <= 20; i++) {
      final x = size.width * (.025 + i * .0475);
      canvas.drawRect(Rect.fromLTWH(x, fenceY - tile * .12, tile * .18, tile * .9), p);
    }

    // Chunky tree canopies in the corners.
    for (final point in <Offset>[
      Offset(size.width * .04, size.height * .06),
      Offset(size.width * .95, size.height * .07),
      Offset(size.width * .96, size.height * .66),
      Offset(size.width * .05, size.height * .79),
    ]) {
      p.color = const Color(0xFF63462C);
      canvas.drawRect(Rect.fromLTWH(point.dx + tile * .35, point.dy + tile * .45, tile * .42, tile * .85), p);
      p.color = const Color(0xFF2E663A);
      canvas.drawRect(Rect.fromLTWH(point.dx, point.dy, tile * 1.45, tile * 1.1), p);
      p.color = const Color(0xFF438443);
      canvas.drawRect(Rect.fromLTWH(point.dx + tile * .18, point.dy + tile * .14, tile * .92, tile * .68), p);
      p.color = const Color(0xFF79AE48);
      canvas.drawRect(Rect.fromLTWH(point.dx + tile * .36, point.dy + tile * .22, tile * .28, tile * .22), p);
    }
  }

  void _building(Canvas canvas, Paint p, Rect body, Color wall, Color roof) {
    p.color = const Color(0xFF514332);
    canvas.drawRect(body.shift(const Offset(3, 4)), p);
    p.color = wall;
    canvas.drawRect(body, p);
    p.color = roof;
    final roofRect = Rect.fromLTWH(body.left - body.width * .08, body.top - body.height * .15,
      body.width * 1.16, body.height * .43);
    canvas.drawRect(roofRect, p);
    p.color = const Color(0xFFE6C37C);
    canvas.drawRect(Rect.fromLTWH(body.left + body.width * .13, body.top + body.height * .35,
      body.width * .18, body.height * .22), p);
    canvas.drawRect(Rect.fromLTWH(body.left + body.width * .69, body.top + body.height * .35,
      body.width * .18, body.height * .22), p);
    p.color = const Color(0xFF65432C);
    canvas.drawRect(Rect.fromLTWH(body.left + body.width * .42, body.top + body.height * .48,
      body.width * .17, body.height * .52), p);
  }

  @override
  bool shouldRepaint(covariant _PixelFarmGroundPainter oldDelegate) => false;
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
