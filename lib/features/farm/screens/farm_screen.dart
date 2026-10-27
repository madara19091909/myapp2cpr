import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/cartoon_button.dart';
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
      final result = g.harvest(i);
      if (result != null) {
        final extra = result.levelsGained > 0
            ? '\n🎉 ارتقيت للمستوى ${g.level}! +${result.levelsGained * GameState.levelUpGoldReward} 🪙'
            : '';
        showToast(
          context,
          'خزّنت ${result.harvestedCount} محصول 🌾  •  +${result.xp} XP$extra',
          color: AppColors.green,
        );
      }
    } else {
      showToast(context, 'المحصول لم ينضج بعد ⏳');
    }
  }

  void _waterPlot(BuildContext context, int index) {
    final game = context.read<GameState>();
    final error = game.waterPlot(index);
    showToast(
      context,
      error ?? 'تم سقي المحصول! 💧 قلّ وقت نموه بنسبة 25%',
      color: error == null ? AppColors.green : AppColors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 5 : width >= 600 ? 4 : 3;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sky, Color(0xFFBFEFFF), Color(0xFF8BD35B), AppColors.grass],
          stops: [0, .22, .23, 1],
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('☁️', style: TextStyle(fontSize: 30)),
                Text('☀️', style: TextStyle(fontSize: 36)),
                Text('☁️', style: TextStyle(fontSize: 26)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: CartoonCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7D8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text('🌾', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('مزرعتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.dark)),
                        SizedBox(height: 2),
                        Text('ازرع، انتظر، واحصد أرباحك', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  _FarmCount(label: 'جاهز للحصاد', value: game.plots.where((plot) => !plot.isEmpty && plot.isReady(DateTime.now())).length, emoji: '✨'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _Badge('⚡ الوقت ×${(1 / game.speedFactor).toStringAsFixed(1)}'),
                _Badge('🌾 كمية الحصاد ×${game.yieldMultiplier}'),
                _Badge('🐾 حيوانات أليفة +${game.petBonusPercent}%'),
                _Badge('💧 الماء ${game.waterUnits}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.water_drop, size: 18),
                label: Text('شراء 10 وحدات ماء — ${formatIqd(GameState.waterPackPrice)}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF075985),
                  backgroundColor: const Color(0xFFE0F7FA),
                  side: const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  final error = context.read<GameState>().buyWater();
                  showToast(context, error ?? 'اشتريت 10 وحدات ماء 💧',
                      color: error == null ? AppColors.green : AppColors.red);
                },
              ),
            ),
          ),
          if (game.plots.any((plot) => !plot.isEmpty && plot.isReady(DateTime.now())))
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: SizedBox(
                width: double.infinity,
                child: CartoonButton(
                  color: AppColors.orange,
                  leading: '🌾',
                  label: 'احصد كل المحاصيل الجاهزة',
                  onPressed: () {
                    final result = context.read<GameState>().harvestAllReady();
                    if (result == null) return;
                    final extra = result.levelsGained > 0
                        ? ' • ارتقيت للمستوى ${context.read<GameState>().level} 🎉'
                        : '';
                    showToast(
                      context,
                      'خزّنت ${result.harvestedCount} محصول 🌾 • +${result.xp} XP$extra',
                      color: AppColors.green,
                    );
                  },
                ),
              ),
            ),
          if (game.canExpandFarm)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
              child: CartoonCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Text('🧱', style: TextStyle(fontSize: 25)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('وسّع مزرعتك  ${game.plots.length}/${GameState.maxPlotCount}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.dark, fontSize: 13)),
                          Text('المساحة التالية: ${formatIqd(game.nextPlotPrice)} • المستوى ${game.nextPlotRequiredLevel}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 112,
                      child: CartoonButton(
                        height: 40,
                        fontSize: 12,
                        leading: '➕',
                        label: 'فتح مساحة',
                        color: AppColors.green,
                        onPressed: () {
                          final error = context.read<GameState>().unlockPlot();
                          showToast(context, error ?? 'تم فتح مساحة زراعة جديدة! 🌱',
                              color: error == null ? AppColors.green : AppColors.red);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: TickerBuilder(
              builder: (context, now) => GridView.builder(
                key: const PageStorageKey<String>('farm-plots-grid'),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                itemCount: game.plots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: width < 360 ? .92 : 1,
                ),
                itemBuilder: (context, index) => PlotTile(
                  key: ValueKey('plot-$index-${game.plots[index].cropId ?? "empty"}'),
                  plot: game.plots[index],
                  now: now,
                  onTap: () => _onTap(context, index),
                  onWater: () => _waterPlot(context, index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmCount extends StatelessWidget {
  const _FarmCount({required this.label, required this.value, required this.emoji});

  final String label;
  final int value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 62),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$emoji $value', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.dark)),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.soilDark, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 2), blurRadius: 2)],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.dark),
      ),
    );
  }
}
