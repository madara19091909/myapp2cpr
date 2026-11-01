import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
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

  static Future<void> _toastResult(BuildContext context, Future<String?> errorFuture, String okMsg) async {
    final error = await errorFuture;
    if (!context.mounted) return;
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

  Future<void> _onTap(BuildContext context, int i) async {
    final g = context.read<GameState>();
    if (i >= g.plots.length) return;
    final plot = g.plots[i];
    final now = g.serverNow;

    if (plot.isEmpty) {
      HapticFeedback.selectionClick();
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => SeedPicker(plotIndex: i),
      );
    } else if (plot.isReady(now)) {
      final result = await g.harvest(i);
      if (!context.mounted) return;
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

  Future<void> _waterPlot(BuildContext context, int index) async {
    final error = context.read<GameState>().waterPlot(index);
    await _toastResult(context, error, 'تم سقي المحصول! 💧 قلّ وقت نموه بنسبة 25%');
  }

  Future<void> _harvestAll(BuildContext context) async {
    final g = context.read<GameState>();
    final result = await g.harvestAllReady();
    if (!context.mounted || result == null) return;
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
            colors: [Color(0xFF9EDCF5), Color(0xFFD7F3E7), Color(0xFFA6DE82), Color(0xFF79C85B)],
            stops: [0, .20, .21, 1],
          ),
        ),
        // Ticker واحد للشاشة كلها: now وعدد الجاهز يُحسبون مرة وحدة
        child: TickerBuilder(
          builder: (context, _) {
            final now = game.serverNow;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: const [
          BoxShadow(color: Color(0x18304B32), blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE2F5DD), Color(0xFFC9EBCB)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.park_rounded, color: Color(0xFF347A50), size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('مزرعتك اليوم', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF263C2D))),
                SizedBox(height: 2),
                Text('ازرع واعتنِ بمحاصيلك حتى تحصد الأرباح', style: TextStyle(fontSize: 10, color: Color(0xFF78877B))),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: readyCount > 0 ? const Color(0xFFFFF2CF) : const Color(0xFFF0F5EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$readyCount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: readyCount > 0 ? const Color(0xFF9A6B13) : const Color(0xFF55715B))),
                const Text('جاهز', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF78877B))),
              ],
            ),
          ),
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
      child: FilledButton.tonalIcon(
        icon: const Icon(Icons.water_drop_rounded, size: 17),
        label: Text('شراء 10 وحدات ماء — ${formatIqd(GameState.waterPackPrice)}'),
        style: FilledButton.styleFrom(
          foregroundColor: const Color(0xFF176A8A),
          backgroundColor: const Color(0xFFE8F7FC),
          padding: const EdgeInsets.symmetric(vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x1C294D2F), blurRadius: 16, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFFFF1E8), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.grid_view_rounded, color: Color(0xFFB76C43), size: 22),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('مساحة المزرعة  ${game.plots.length}/${GameState.maxPlotCount}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF263C2D), fontSize: 12)),
                const SizedBox(height: 3),
                Text('التوسعة التالية ${formatIqd(game.nextPlotPrice)} • المستوى ${game.nextPlotRequiredLevel}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF78877B), fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF347A50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
            onPressed: onUnlock,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('توسعة'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .85)),
        boxShadow: const [BoxShadow(color: Color(0x120F2816), offset: Offset(0, 2), blurRadius: 5)],
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF405947))),
    );
  }
}
