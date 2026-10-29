import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ---------- Helpers ----------

  static int _readyCount(GameState g, DateTime now) =>
      g.plots.where((p) => !p.isEmpty && p.isReady(now)).length;

  static void _toastHarvest(
    BuildContext context, {
    required int count,
    required int xp,
    required int levelsGained,
    required int level,
  }) {
    HapticFeedback.mediumImpact();
    final extra = levelsGained > 0
        ? '\n🎉 ارتقيت للمستوى $level! +${levelsGained * GameState.levelUpGoldReward} 🪙'
        : '';
    showToast(
      context,
      'خزّنت $count محصول 🌾  •  +$xp XP$extra',
      color: AppColors.green,
    );
  }

  static void _toastResult(BuildContext context, String? error, String okMsg) {
    if (error == null) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    showToast(
      context,
      error ?? okMsg,
      color: error == null ? AppColors.green : AppColors.red,
    );
  }

  // ---------- Actions ----------

  void _onTap(BuildContext context, int i) {
    final g = context.read<GameState>();
    if (i >= g.plots.length) return;
    final plot = g.plots[i];
    final now = DateTime.now();

    if (plot.isEmpty) {
      HapticFeedback.selectionClick();
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => SeedPicker(plotIndex: i),
      );
    } else if (plot.isReady(now)) {
      final result = g.harvest(i);
      if (result != null) {
        _toastHarvest(
          context,
          count: result.harvestedCount,
          xp: result.xp,
          levelsGained: result.levelsGained,
          level: g.level,
        );
      }
    } else {
      HapticFeedback.selectionClick();
      showToast(context, 'المحصول لم ينضج بعد ⏳');
    }
  }

  void _waterPlot(BuildContext context, int index) {
    final error = context.read<GameState>().waterPlot(index);
    _toastResult(context, error, 'تم سقي المحصول! 💧 قلّ وقت نموه بنسبة 25%');
  }

  void _harvestAll(BuildContext context) {
    final g = context.read<GameState>();
    final result = g.harvestAllReady();
    if (result == null) return;
    _toastHarvest(
      context,
      count: result.harvestedCount,
      xp: result.xp,
      levelsGained: result.levelsGained,
      level: g.level,
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 5 : width >= 600 ? 4 : 3;
    final speed = game.speedFactor > 0 ? 1 / game.speedFactor : 1.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sky, Color(0xFFBFEFFF), Color(0xFF8BD35B), AppColors.grass],
            stops: [0, .22, .23, 1],
          ),
        ),
        // Ticker واحد للشاشة كلها: now وعدد الجاهز يُحسبون مرة وحدة
        child: TickerBuilder(
          builder: (context, now) {
            final ready = _readyCount(game, now);

            return CustomScrollView(
              key: const PageStorageKey<String>('farm-scroll'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Sky()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                    child: _Header(readyCount: ready),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _Badge('${game.weather.emoji} ${game.weather.name}'),
                        _Badge('${game.season.emoji} ${game.season.name}'),
                        _Badge('${game.weeklyEvent.emoji} ${game.weeklyEvent.title}'),
                        _Badge('⚡ الوقت ×${speed.toStringAsFixed(1)}'),
                        _Badge('🌾 كمية ×${game.yieldMultiplier}'),
                        _Badge('🐾 أليفة +${game.petBonusPercent}%'),
                        _Badge('💧 ${game.waterUnits}'),
                        if (game.ownedBuildings.isNotEmpty) _Badge('🏗️ ${game.ownedBuildings.length} مبنى'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                    child: _WaterButton(
                      onPressed: () => _toastResult(
                        context,
                        context.read<GameState>().buyWater(),
                        'اشتريت ${GameState.waterPackSize} وحدات ماء 💧',
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: ready == 0
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                            child: SizedBox(
                              width: double.infinity,
                              child: CartoonButton(
                                color: AppColors.orange,
                                leading: '🌾',
                                label: 'احصد كل المحاصيل الجاهزة ($ready)',
                                onPressed: () => _harvestAll(context),
                              ),
                            ),
                          ),
                  ),
                ),
                if (game.canExpandFarm)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
                      child: _ExpandCard(
                        game: game,
                        onUnlock: () => _toastResult(
                          context,
                          context.read<GameState>().unlockPlot(),
                          'تم فتح مساحة زراعة جديدة! 🌱',
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: width < 360 ? .92 : 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => PlotTile(
                        key: ValueKey('plot-$index-${game.plots[index].cropId ?? "empty"}'),
                        plot: game.plots[index],
                        now: now,
                        onTap: () => _onTap(context, index),
                        onWater: () => _waterPlot(context, index),
                      ),
                      childCount: game.plots.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------- Widgets ----------

/// سماء متحركة: الشمس والغيوم تطفو بهدوء
class _Sky extends StatefulWidget {
  const _Sky();

  @override
  State<_Sky> createState() => _SkyState();
}

class _SkyState extends State<_Sky> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _float(String emoji, double size, double amp, double phase) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform((_c.value + phase) % 1);
        return Transform.translate(
          offset: Offset((t - .5) * amp, 0),
          child: Text(emoji, style: TextStyle(fontSize: size)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _float('☁️', 30, 14, 0),
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.scale(
              scale: 1 + _c.value * .06,
              child: const Text('☀️', style: TextStyle(fontSize: 36)),
            ),
          ),
          _float('☁️', 26, 18, .5),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.readyCount});

  final int readyCount;

  @override
  Widget build(BuildContext context) {
    return CartoonCard(
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
                Text('مزرعتي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.dark)),
                SizedBox(height: 2),
                Text('ازرع، انتظر، واحصد أرباحك',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          _FarmCount(label: 'جاهز للحصاد', value: readyCount, emoji: '✨'),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
        onPressed: onPressed,
      ),
    );
  }
}

class _ExpandCard extends StatelessWidget {
  const _ExpandCard({required this.game, required this.onUnlock});

  final GameState game;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return CartoonCard(
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
              onPressed: onUnlock,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(minWidth: 62),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: value > 0 ? const Color(0xFFFFE680) : const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$emoji $value',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.dark)),
          Text(label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted)),
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
        color: Colors.white.withValues(alpha: .9), // Flutter < 3.27: withOpacity(.9)
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