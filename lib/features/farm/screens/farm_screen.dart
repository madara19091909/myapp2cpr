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
    final crossAxisCount = MediaQuery.of(context).size.width >= 600 ? 4 : 3;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sky, Color(0xFFBFEFFF), AppColors.grass, Color(0xFF4FA82B)],
          stops: [0, .22, .24, 1],
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('☁️', style: TextStyle(fontSize: 34)),
                Text('☀️', style: TextStyle(fontSize: 40)),
                Text('☁️', style: TextStyle(fontSize: 28)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _Badge('⚡ الوقت ×${(1 / g.speedFactor).toStringAsFixed(1)}'),
                _Badge('💰 الحصاد ×${g.yieldMultiplier}'),
                _Badge('🐾 حيوانات أليفة +${g.petBonusPercent}%'),
              ],
            ),
          ),
          Expanded(
            child: TickerBuilder(
              builder: (context, now) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: g.plots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
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
