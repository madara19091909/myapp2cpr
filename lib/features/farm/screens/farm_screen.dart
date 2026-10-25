import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ticker_builder.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
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
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 600 ? 4 : 3;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9E9FF), Color(0xFFEAF8D9), Color(0xFF78C34B)],
          stops: [0, .42, 1],
        ),
      ),
      child: Column(
        children: [
          const _FarmWelcomeScene(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
            child: Wrap(
              spacing: 6,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: [
                _Badge('⚡ الوقت ×${(1 / g.speedFactor).toStringAsFixed(1)}'),
                _Badge('🌾 الحصاد ×${g.yieldMultiplier}'),
                _Badge('🐾 الحيوانات +${g.petBonusPercent}%'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 7),
            child: Row(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text('حقول مزرعتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF315D25))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF679B3B), width: 1.5)),
                  child: Text('${g.plots.length} قطعة', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF315D25))),
                ),
              ],
            ),
          ),
          Expanded(
            child: TickerBuilder(
              builder: (context, now) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(13, 2, 13, 16),
                itemCount: g.plots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .96,
                ),
                itemBuilder: (context, i) => PlotTile(
                  plot: g.plots[i],
                  now: now,
                  onTap: () => _onTap(context, i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _FarmWelcomeScene extends StatelessWidget {
  const _FarmWelcomeScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      margin: const EdgeInsets.fromLTRB(12, 9, 12, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF805126), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33704420), blurRadius: 7, offset: Offset(0, 4))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6CC7F4), Color(0xFFD8F2A4), Color(0xFF69B747)], stops: [0, .54, .55]),
            ),
          ),
          Positioned(top: 7, left: 14, child: Text('☁️', style: TextStyle(fontSize: 24))),
          Positioned(top: 17, right: 28, child: Text('☁️', style: TextStyle(fontSize: 20))),
          Positioned(top: 48, left: 0, right: 0, child: Container(height: 2, color: const Color(0x5586A64C))),
          Positioned(left: 14, bottom: 30, child: Text('🌳', style: TextStyle(fontSize: 43))),
          Positioned(right: 6, bottom: 29, child: Text('🌳', style: TextStyle(fontSize: 46))),
          Positioned(left: 60, bottom: 20, child: Text('🏡', style: TextStyle(fontSize: 68))),
          Positioned(right: 56, bottom: 20, child: Text('🏚️', style: TextStyle(fontSize: 65))),
          Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 22, color: const Color(0xFF7A4B29))),
          const Positioned(left: 15, bottom: 2, child: Text('🌼  🌱  🌷  🌱  🌼', style: TextStyle(fontSize: 15))),
          const Positioned(right: 12, bottom: 2, child: Text('🌻  🌱  🌼', style: TextStyle(fontSize: 15))),
          Positioned(left: 12, top: 10, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFDF1D0), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF8B5B2D), width: 2)),
            child: const Text('مزرعتي الجميلة', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF57391E), fontSize: 13)),
          )),
          const Positioned(left: 17, bottom: 27, child: Text('🐔', style: TextStyle(fontSize: 24))),
          const Positioned(right: 103, bottom: 27, child: Text('🐄', style: TextStyle(fontSize: 27))),
          const Positioned(right: 18, bottom: 28, child: Text('🐑', style: TextStyle(fontSize: 23))),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.soilDark, width: 2),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.dark)),
    );
  }
}
