import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ticker_builder.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../widgets/plot_tile.dart';
import '../widgets/seed_picker.dart';

// ═══════════════════════════════════════════════════════════════════
//  FarmScreen — النسخة الخارقة
// ═══════════════════════════════════════════════════════════════════
class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sceneCtrl;   // حركة المشهد (24s loop)
  late final AnimationController _entranceCtrl; // دخول الشاشة

  @override
  void initState() {
    super.initState();
    _sceneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _sceneCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ────────────────────────── منطق النقر ──────────────────────────
  Future<void> _onTap(BuildContext context, int i) async {
    HapticFeedback.lightImpact();
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
      HapticFeedback.mediumImpact();
      final r = g.harvest(i);
      if (r != null) {
        final extra = r.levelsGained > 0
            ? '\n🎉 ارتقيت للمستوى ${g.level}! +${r.levelsGained * GameState.levelUpGoldReward} 🪙'
            : '';
        showToast(
          context,
          '+${formatIqd(r.income)}  •  +${r.xp} XP$extra',
          color: AppColors.green,
        );
      }
    } else {
      HapticFeedback.selectionClick();
      showToast(context, 'المحصول لم ينضج بعد ⏳');
    }
  }

  // ──────────────────────────── build ────────────────────────────
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 5 : (width >= 600 ? 4 : 3);

    final fadeIn = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB9E9FF),
            Color(0xFFEAF8D9),
            Color(0xFF78C34B),
          ],
          stops: [0, .42, 1],
        ),
      ),
      child: Stack(
        children: [
          // ✨ جزيئات طافية في الخلفية
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sceneCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _SkyParticlesPainter(t: _sceneCtrl.value),
                ),
              ),
            ),
          ),

          Column(
            children: [
              FadeTransition(
                opacity: fadeIn,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _entranceCtrl,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Column(
                    children: [
                      _FarmWelcomeScene(animation: _sceneCtrl),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: _BadgesRow(gameState: g),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                        child: _PlotsHeader(plotCount: g.plots.length),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: TickerBuilder(
                  builder: (context, now) => GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(13, 2, 13, 16),
                    itemCount: g.plots.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: .92,
                    ),
                    itemBuilder: (context, i) {
                      return _StaggeredAppear(
                        index: i,
                        controller: _entranceCtrl,
                        child: RepaintBoundary(
                          child: PlotTile(
                            plot: g.plots[i],
                            now: now,
                            onTap: () => _onTap(context, i),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  المشهد الحي — سماء، شمس، سحب، طيور، أشجار، حيوانات
// ═══════════════════════════════════════════════════════════════════
class _FarmWelcomeScene extends StatelessWidget {
  const _FarmWelcomeScene({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      margin: const EdgeInsets.fromLTRB(12, 9, 12, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF805126), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33704420),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 🌤️ سماء → أرض
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF6CC7F4),
                      Color(0xFFD8F2A4),
                      Color(0xFF69B747),
                    ],
                    stops: [0, .54, .55],
                  ),
                ),
              ),

              // ☀️ شمس بأشعة دوّارة
              Positioned(
                top: 8,
                right: 12,
                width: 46,
                height: 46,
                child: Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: CustomPaint(painter: _SunRaysPainter()),
                ),
              ),

              // ☁️ سحب منجرفة
              _drift(
                t: t,
                from: -60,
                to: 480,
                top: 6,
                child: const Text('☁️', style: TextStyle(fontSize: 26)),
              ),
              _drift(
                t: (t + .35) % 1,
                from: -60,
                to: 480,
                top: 16,
                child: const Text('☁️', style: TextStyle(fontSize: 20)),
              ),
              _drift(
                t: (t + .70) % 1,
                from: 500,
                to: -60,
                top: 10,
                child: const Text('☁️', style: TextStyle(fontSize: 22)),
              ),

              // 🐦 طيور طائرة
              _drift(
                t: (t + .15) % 1,
                from: -40,
                to: 520,
                top: 44,
                child: const Text('🐦', style: TextStyle(fontSize: 16)),
              ),
              _drift(
                t: (t + .55) % 1,
                from: 520,
                to: -40,
                top: 58,
                child: const Text('🐦', style: TextStyle(fontSize: 13)),
              ),

              // خط الأفق
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Container(height: 2, color: const Color(0x5586A64C)),
              ),

              // 🌳 أشجار تتمايل
              Positioned(
                left: 14,
                bottom: 30,
                child: Transform.rotate(
                  angle: math.sin(t * 2 * math.pi * 2) * .05,
                  alignment: Alignment.bottomCenter,
                  child: const Text('🌳', style: TextStyle(fontSize: 43)),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 29,
                child: Transform.rotate(
                  angle: math.sin(t * 2 * math.pi * 2 + 1) * .05,
                  alignment: Alignment.bottomCenter,
                  child: const Text('🌳', style: TextStyle(fontSize: 46)),
                ),
              ),

              // 🏡 بيت بنافذة تنبض
              Positioned(
                left: 60,
                bottom: 20,
                child: Stack(
                  children: [
                    const Text('🏡', style: TextStyle(fontSize: 68)),
                    Positioned(
                      left: 28,
                      top: 34,
                      child: Opacity(
                        opacity: .5 + .5 * math.sin(t * 2 * math.pi * 3),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE98A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFFE98A),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 56,
                bottom: 20,
                child: Text('🏚️', style: TextStyle(fontSize: 65)),
              ),

              // أرض ترابية
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 22, color: const Color(0xFF7A4B29)),
              ),

              const Positioned(
                left: 15,
                bottom: 2,
                child: Text('🌼  🌱  🌷  🌱  🌼',
                    style: TextStyle(fontSize: 15)),
              ),
              const Positioned(
                right: 12,
                bottom: 2,
                child: Text('🌻  🌱  🌼', style: TextStyle(fontSize: 15)),
              ),

              // لوحة العنوان
              Positioned(
                left: 12,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF1D0),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: const Color(0xFF8B5B2D), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'مزرعتي الجميلة',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF57391E),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // 🐔 🐄 🐑 حيوانات "تتنفس"
              _breathe(
                t: t,
                left: 17,
                bottom: 27,
                child: const Text('🐔', style: TextStyle(fontSize: 24)),
              ),
              _breathe(
                t: (t + .33) % 1,
                right: 103,
                bottom: 27,
                child: const Text('🐄', style: TextStyle(fontSize: 27)),
              ),
              _breathe(
                t: (t + .66) % 1,
                right: 18,
                bottom: 28,
                child: const Text('🐑', style: TextStyle(fontSize: 23)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _drift({
    required double t,
    required double from,
    required double to,
    required double top,
    required Widget child,
  }) {
    final x = from + (to - from) * t;
    return Positioned(top: top, left: x, child: child);
  }

  Widget _breathe({
    required double t,
    double? left,
    double? right,
    double? bottom,
    required Widget child,
  }) {
    final s = 1 + .06 * math.sin(t * 2 * math.pi * 4);
    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.scale(scale: s, child: child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  رسام أشعة الشمس
// ═══════════════════════════════════════════════════════════════════
class _SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final rayPaint = Paint()
      ..color = const Color(0xFFFFE066).withOpacity(.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * (r * .55), c + dir * (r * .9), rayPaint);
    }

    canvas.drawCircle(
      c,
      r * .42,
      Paint()
        ..color = const Color(0xFFFFE066)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      c,
      r * .42,
      Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  جزيئات خلفية طافية (pollen / sparkles)
// ═══════════════════════════════════════════════════════════════════
class _SkyParticlesPainter extends CustomPainter {
  _SkyParticlesPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 14; i++) {
      final seed = i * 97.13;
      final x = ((seed + t * 180) % (size.width + 40)) - 20;
      final yBase = (seed * 1.7) % (size.height * .55);
      final y = yBase + 6 * math.sin(t * 6 + i);
      final r = 1.4 + (i % 3) * .8;
      final opacity = (.25 + .35 * math.sin(t * 4 + i)).clamp(.05, .7);
      canvas.drawCircle(
        Offset(x, y),
        r,
        paint..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyParticlesPainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════════
//  صف الشارات
// ═══════════════════════════════════════════════════════════════════
class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.gameState});
  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      alignment: WrapAlignment.center,
      children: [
        _Badge(
          icon: '⚡',
          label: 'الوقت ×${(1 / gameState.speedFactor).toStringAsFixed(1)}',
        ),
        _Badge(
          icon: '🌾',
          label: 'الحصاد ×${gameState.yieldMultiplier}',
        ),
        _Badge(
          icon: '🐾',
          label: 'الحيوانات +${gameState.petBonusPercent}%',
        ),
      ],
    );
  }
}

class _Badge extends StatefulWidget {
  const _Badge({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final shimmer = (math.sin(_ctrl.value * 2 * math.pi) + 1) / 2;
        return Transform.scale(
          scale: 1 + .02 * shimmer,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(.95),
                  Color.lerp(Colors.white,
                      AppColors.green.withOpacity(.22), shimmer)!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.soilDark, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  رأس قسم الحقول
// ═══════════════════════════════════════════════════════════════════
class _PlotsHeader extends StatelessWidget {
  const _PlotsHeader({required this.plotCount});
  final int plotCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('🌱', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 7),
        const Expanded(
          child: Text(
            'حقول مزرعتك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF315D25),
            ),
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.85),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFF679B3B), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌿', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                '$plotCount قطعة',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF315D25),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ظهور متدرّج لبطاقات الحقول
// ═══════════════════════════════════════════════════════════════════
class _StaggeredAppear extends StatelessWidget {
  const _StaggeredAppear({
    required this.index,
    required this.controller,
    required this.child,
  });
  final int index;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index * .06).clamp(0.0, .45);
    final end = (delay + .55).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, end, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: .88, end: 1).animate(anim),
        child: child,
      ),
    );
  }
}