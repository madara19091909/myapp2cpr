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

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _sceneFade;
  final List<GlobalKey> _plotKeys = [];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _sceneFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, .45, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// تقدّم حركة العنصر رقم [i] (دخول متتابع متدرّج).
  double _stagger(int i, {double base = 300, double step = 80, double dur = 450}) {
    final ms = _entrance.value * _entrance.duration.inMilliseconds;
    return (((ms - (base + i * step)) / dur)).clamp(0.0, 1.0);
  }

  // ─── تفاعل ───────────────────────────────────────────────────────────────

  void _onTap(BuildContext context, int i) {
    final g = context.read<GameState>();
    final plot = g.plots[i];
    final now = DateTime.now();

    if (plot.isEmpty) {
      HapticFeedback.lightImpact();
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
        _celebrateHarvest(context, i, r.income, r.xp);
        final extra = r.levelsGained > 0
            ? '\n🎉 ارتقيت للمستوى ${g.level}! +${r.levelsGained * GameState.levelUpGoldReward} 🪙'
            : '';
        showToast(context, '+${formatIqd(r.income)}  •  +${r.xp} XP$extra', color: AppColors.green);
      }
    } else {
      HapticFeedback.selectionClick();
      showToast(context, 'المحصول لم ينضج بعد ⏳');
    }
  }

  /// انفجار احتفالي: عملات و✨ تتطاير من موضع القطعة المُحصودة.
  void _celebrateHarvest(BuildContext context, int i, int income, int xp) {
    final box = _plotKeys[i].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final pos = box.localToGlobal(box.size.center(Offset.zero));
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _HarvestBurst(
        position: pos,
        income: income,
        xp: xp,
        onDone: entry.remove,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  // ─── البناء ──────────────────────────────────────────────────────────────

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
          _FarmScene(entrance: _sceneFade),

          // شريط الإحصاءات
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _StatChip(
                  icon: '⚡',
                  label: 'الوقت',
                  value: '×${(1 / g.speedFactor).toStringAsFixed(1)}',
                  progress: _stagger(0),
                  tint: const Color(0xFFFFC93C),
                ),
                _StatChip(
                  icon: '🌾',
                  label: 'الحصاد',
                  value: '×${g.yieldMultiplier}',
                  progress: _stagger(1),
                  tint: const Color(0xFF8BC34A),
                ),
                _StatChip(
                  icon: '🐾',
                  label: 'الحيوانات',
                  value: '+${g.petBonusPercent}%',
                  progress: _stagger(2),
                  tint: const Color(0xFFBA68C8),
                ),
              ],
            ),
          ),

          // العنوان + عدّاد الجاهز + عدد القطع
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF679B3B), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: const Text('🌱', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حقول مزرعتك',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF315D25)),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 3.5,
                        width: 66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(colors: [Color(0xFFF6A821), Color(0xFFF6A82100)]),
                        ),
                      ),
                    ],
                  ),
                ),
                TickerBuilder(
                  builder: (context, now) {
                    final ready = g.plots.where((p) => p.isReady(now)).length;
                    return _ReadyPill(count: ready, now: now);
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.85),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFF679B3B), width: 1.5),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '${g.plots.length} قطعة',
                      key: ValueKey(g.plots.length),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF315D25)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // الشبكة
          Expanded(
            child: TickerBuilder(
              builder: (context, now) => RepaintBoundary(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(13, 2, 13, 16),
                  itemCount: g.plots.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .96,
                  ),
                  itemBuilder: (context, i) {
                    while (_plotKeys.length <= i) {
                      _plotKeys.add(GlobalKey());
                    }
                    return KeyedSubtree(
                      key: _plotKeys[i],
                      child: _Entrance(
                        progress: _stagger(i, base: 480, step: 65, dur: 420),
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
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ المشهد الحي ═══════════════════════════

class _FarmScene extends StatefulWidget {
  const _FarmScene({required this.entrance});

  final Animation<double> entrance;

  @override
  State<_FarmScene> createState() => _FarmSceneState();
}

class _FarmSceneState extends State<_FarmScene> {
  /// كاش لمرسومات الإيموجي حتى لا نعيد layout كل إطار.
  final Map<String, TextPainter> _emojiCache = {};

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.entrance,
      child: Container(
        height: 192,
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF805126), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x33704420), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TickerBuilder(
              builder: (context, now) => RepaintBoundary(
                child: CustomPaint(painter: _FarmScenePainter(now: now, emojiCache: _emojiCache)),
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF1D0),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFF8B5B2D), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 2))],
                ),
                child: const Text(
                  '☀️ مزرعتي الجميلة',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF57391E), fontSize: 13),
                ),
              ),
            ),
            const Positioned(
              left: 12,
              bottom: 8,
              child: Text('🧑‍🌾', style: TextStyle(fontSize: 30)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmScenePainter extends CustomPainter {
  _FarmScenePainter({required this.now, required this.emojiCache});

  final DateTime now;
  final Map<String, TextPainter> emojiCache;

  double get t => now.millisecondsSinceEpoch / 1000.0;

  // ── السماء ──
  void _paintSky(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3FA9E8), Color(0xFF9BDCF7), Color(0xFFEAF7C8)],
        ).createShader(rect),
    );
  }

  // ── الشمس: نواة متدرجة + 12 شعاعاً دوّاراً نابضاً + هالة ──
  void _paintSun(Canvas canvas, double w, double h) {
    final c = Offset(w * 0.845, 36);
    const r = 21.0;

    canvas.drawCircle(
      c,
      r * 3.2,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x66FFE58A), const Color(0x00FFE58A)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 3.2)),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    final rayPaint = Paint()
      ..color = const Color(0xB3FFB300)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rot = t * 0.25;
    for (var i = 0; i < 12; i++) {
      final a = rot + i * math.pi / 6;
      final len = r * (1.5 + 0.15 * math.sin(t * 2 + i));
      canvas.drawLine(
        c + Offset(math.cos(a) * r * 1.3, math.sin(a) * r * 1.3),
        c + Offset(math.cos(a) * len, math.sin(a) * len),
        rayPaint,
      );
    }
  }

  // ── غيوم منجرفة بسرعات وأحجام مختلفة ──
  void _paintClouds(Canvas canvas, double w, double h) {
    const clouds = [
      (y: 26.0, speed: 11.0, scale: 1.0, offset: 0.0),
      (y: 46.0, speed: 17.0, scale: 0.68, offset: 150.0),
      (y: 15.0, speed: 7.5, scale: 0.55, offset: 280.0),
    ];
    for (final c in clouds) {
      final x = ((t * c.speed + c.offset) % (w + 200)) - 100;
      canvas
        ..save()
        ..translate(x, c.y)
        ..scale(c.scale);
      final paint = Paint()..color = Colors.white.withOpacity(.92);
      canvas
        ..drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-26, -8, 52, 18), const Radius.circular(12)), paint)
        ..drawCircle(const Offset(-12, -10), 12, paint)
        ..drawCircle(const Offset(6, -13), 14, paint)
        ..drawCircle(const Offset(20, -8), 10, paint)
        ..restore();
    }
  }

  // ── طيور تطير بأجنحة ترفرف ──
  void _paintBirds(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF3E4A5A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final p = (t * 0.045 + i * 0.37) % 1.0;
      final x = p * (w + 80) - 40;
      final y = h * 0.14 + i * 14 + math.sin(t * 2 + i * 2) * 5;
      final flap = math.sin(t * 7 + i) * 4;
      canvas.drawPath(
        Path()
          ..moveTo(x - 8, y)
          ..quadraticBezierTo(x - 3, y - 5 - flap, x, y)
          ..quadraticBezierTo(x + 3, y - 5 - flap, x + 8, y),
        paint,
      );
    }
  }

  // ── تلال مزدوجة ──
  void _paintHills(Canvas canvas, double w, double h, {required bool far}) {
    final baseY = far ? h * 0.56 : h * 0.66;
    final amp = far ? h * 0.045 : h * 0.05;
    final color = far ? const Color(0xFF93CC63) : const Color(0xFF6FBE45);
    final freq = far ? 2.2 : 1.6;
    final phase = far ? 0.0 : 1.3;

    final path = Path()..moveTo(0, baseY);
    for (double x = 0; x <= w; x += 10) {
      path.lineTo(x, baseY - amp - math.sin((x / w) * math.pi * freq + phase) * amp);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ── طاحونة هواء بشفرات تدور ──
  void _paintWindmill(Canvas canvas, double cx, double cy, double s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 12 * s, cy - 58 * s, 24 * s, 58 * s), Radius.circular(5 * s)),
      Paint()..color = const Color(0xFFFAE8C8),
    );
    // قبّة
    canvas.drawPath(
      Path()
        ..moveTo(cx - 14 * s, cy - 56 * s)
        ..lineTo(cx, cy - 72 * s)
        ..lineTo(cx + 14 * s, cy - 56 * s)
        ..close(),
      Paint()..color = const Color(0xFF8B5B2D),
    );
    // باب
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 5 * s, cy - 16 * s, 10 * s, 16 * s), Radius.circular(4 * s)),
      Paint()..color = const Color(0xFF7A4B29),
    );
    // شفرات دوّارة
    final hub = Offset(cx, cy - 58 * s);
    canvas
      ..save()
      ..translate(hub.dx, hub.dy)
      ..rotate(t * 1.2);
    final bladePaint = Paint()..color = const Color(0xFFFFF6E0);
    for (var i = 0; i < 4; i++) {
      canvas
        ..save()
        ..rotate(i * math.pi / 2)
        ..drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, -4 * s, 34 * s, 8 * s), Radius.circular(4 * s)),
          bladePaint,
        )
        ..restore();
    }
    canvas
      ..drawCircle(Offset.zero, 5 * s, Paint()..color = const Color(0xFF8B5B2D))
      ..restore();
  }

  // ── طريق رملي متعرّج ──
  void _paintPath(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.72 - 12, h * 0.74)
      ..cubicTo(w * 0.60, h * 0.82, w * 0.46, h * 0.86, w * 0.40, h + 12);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC9A96B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFEAD49E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── منزل ريفي مع دخان متصاعد من المدخنة ──
  void _paintHouse(Canvas canvas, double cx, double baseY) {
    // جسم
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 30, baseY - 42, 60, 42), const Radius.circular(4)),
      Paint()..color = const Color(0xFFFFF3D6),
    );
    // سقف
    canvas.drawPath(
      Path()
        ..moveTo(cx - 38, baseY - 40)
        ..lineTo(cx, baseY - 68)
        ..lineTo(cx + 38, baseY - 40)
        ..close(),
      Paint()..color = const Color(0xFFB45F3F),
    );
    // مدخنة
    canvas.drawRect(Rect.fromLTWH(cx + 14, baseY - 62, 10, 18), Paint()..color = const Color(0xFF9B4A2F));
    for (var i = 0; i < 3; i++) {
      final p = (t * 0.22 + i / 3) % 1.0;
      canvas.drawCircle(
        Offset(cx + 19 + math.sin(p * 6) * 4, baseY - 68 - p * 34),
        3 + p * 7,
        Paint()..color = Colors.white.withOpacity((1 - p) * 0.5),
      );
    }
    // باب
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 8, baseY - 22, 16, 22), const Radius.circular(6)),
      Paint()..color = const Color(0xFF7A4B29),
    );
    // نوافذ بإطارات
    for (final wx in [-22.0, 12.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx + wx, baseY - 34, 12, 12), const Radius.circular(2)),
        Paint()..color = const Color(0xFF9ADCF0),
      );
      final frame = Paint()
        ..color = const Color(0xFF7A4B29)
        ..strokeWidth = 1.4;
      canvas
        ..drawLine(Offset(cx + wx + 6, baseY - 34), Offset(cx + wx + 6, baseY - 22), frame)
        ..drawLine(Offset(cx + wx, baseY - 28), Offset(cx + wx + 12, baseY - 28), frame);
    }
  }

  // ── حظيرة حمراء صغيرة ──
  void _paintBarn(Canvas canvas, double cx, double baseY) {
    canvas.drawRect(Rect.fromLTWH(cx - 18, baseY - 26, 36, 26), Paint()..color = const Color(0xFFC75B45));
    canvas.drawPath(
      Path()
        ..moveTo(cx - 24, baseY - 24)
        ..lineTo(cx, baseY - 44)
        ..lineTo(cx + 24, baseY - 24)
        ..close(),
      Paint()..color = const Color(0xFF8E3B2C),
    );
    canvas.drawRect(Rect.fromLTWH(cx - 8, baseY - 16, 16, 16), Paint()..color = const Color(0xFF7A3223));
    final beam = Paint()
      ..color = const Color(0xFFFFF1DC)
      ..strokeWidth = 2;
    canvas
      ..drawLine(Offset(cx - 8, baseY - 16), Offset(cx + 8, baseY), beam)
      ..drawLine(Offset(cx + 8, baseY - 16), Offset(cx - 8, baseY), beam);
  }

  // ── شجرة تتمايل ──
  void _paintTree(Canvas canvas, double cx, double baseY, double s, double phase) {
    final sway = math.sin(t * 1.4 + phase) * 0.035;
    canvas
      ..save()
      ..translate(cx, baseY)
      ..rotate(sway);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-4 * s, -26 * s, 8 * s, 26 * s), Radius.circular(4 * s)),
      Paint()..color = const Color(0xFF7A4B29),
    );
    const greens = [Color(0xFF4E9A3D), Color(0xFF5FAE46), Color(0xFF6FBF52)];
    final centers = [Offset(0, -36 * s), Offset(-12 * s, -27 * s), Offset(12 * s, -27 * s)];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(centers[i], 15 * s, Paint()..color = greens[i]);
    }
    canvas.restore();
  }

  void _paintEmoji(Canvas canvas, String e, double size, Offset bottomCenter) {
    final key = '$e|$size';
    final tp = emojiCache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(text: e, style: TextStyle(fontSize: size)),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    tp.paint(canvas, bottomCenter - Offset(tp.width / 2, tp.height));
  }

  // ── حيوانات تنهض وتنخفض ──
  void _paintAnimals(Canvas canvas, double w, double h) {
    final bob = math.sin(t * 3) * 2;
    _paintEmoji(canvas, '🐔', 20, Offset(w * 0.60, h * 0.87 + bob));
    _paintEmoji(canvas, '🐄', 26, Offset(w * 0.30, h * 0.94 - bob));
    _paintEmoji(canvas, '🐑', 20, Offset(w * 0.87, h * 0.97 + bob * 0.7));
  }

  // ── زهور متمايلة على طول الحافة ──
  void _paintFlowers(Canvas canvas, double w, double h) {
    const petals = [Color(0xFFFF8A80), Color(0xFFFFD54F), Color(0xFFBA68C8), Color(0xFF4FC3F7), Color(0xFFFFF176)];
    final stem = Paint()
      ..color = const Color(0xFF4C8A32)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    var idx = 0;
    for (double x = 14; x < w; x += 26) {
      final sway = math.sin(t * 1.8 + x * 0.06) * 3;
      final baseY = h - 9;
      final top = Offset(x + sway, baseY - 13);
      canvas.drawLine(Offset(x, baseY), top, stem);
      final color = petals[idx++ % petals.length];
      for (var p = 0; p < 5; p++) {
        final a = p * (math.pi * 2 / 5) + sway * 0.1;
        canvas.drawCircle(top + Offset(math.cos(a) * 3.4, math.sin(a) * 3.4), 2.3, Paint()..color = color);
      }
      canvas.drawCircle(top, 1.8, Paint()..color = const Color(0xFFFFE082));
    }
  }

  // ── خصلات عشب ──
  void _paintGrassTufts(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF4E9A3D)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (double x = 8; x < w; x += 34) {
      final y = h - 3;
      final sway = math.sin(t * 2 + x) * 2;
      canvas
        ..drawLine(Offset(x, y), Offset(x - 3 + sway, y - 8), paint)
        ..drawLine(Offset(x + 3, y), Offset(x + 4 + sway, y - 10), paint)
        ..drawLine(Offset(x + 6, y), Offset(x + 9 + sway, y - 7), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _paintSky(canvas, Offset.zero & size);
    _paintSun(canvas, w, h);
    _paintClouds(canvas, w, h);
    _paintBirds(canvas, w, h);
    _paintHills(canvas, w, h, far: true);
    _paintWindmill(canvas, w * 0.13, h * 0.60, 1.0);
    _paintHills(canvas, w, h, far: false);
    _paintPath(canvas, w, h);
    _paintHouse(canvas, w * 0.72, h * 0.74);
    _paintBarn(canvas, w * 0.47, h * 0.78);
    _paintTree(canvas, w * 0.045, h * 0.72, 1.0, 0.0);
    _paintTree(canvas, w * 0.96, h * 0.70, 1.15, 1.7);
    _paintAnimals(canvas, w, h);
    _paintFlowers(canvas, w, h);
    _paintGrassTufts(canvas, w, h);
  }

  @override
  bool shouldRepaint(_FarmScenePainter oldDelegate) => oldDelegate.now != now;
}

// ═══════════════════════ الاحتفال بالحصاد ═══════════════════════

class _HarvestBurst extends StatefulWidget {
  const _HarvestBurst({required this.position, required this.income, required this.xp, required this.onDone});

  final Offset position;
  final int income;
  final int xp;
  final VoidCallback onDone;

  @override
  State<_HarvestBurst> createState() => _HarvestBurstState();
}

class _HarvestBurstState extends State<_HarvestBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<Offset> _dirs;
  late final List<String> _coins;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
    _dirs = List.generate(9, (i) {
      final a = -math.pi / 2 + (i - 4) * 0.35 + rng.nextDouble() * 0.2;
      final v = 46 + rng.nextDouble() * 42;
      return Offset(math.cos(a) * v, math.sin(a) * v);
    });
    _coins = List.generate(9, (_) => rng.nextBool() ? '🪙' : '✨');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = Curves.easeOut.transform(_c.value);
        return Positioned(
          left: widget.position.dx - 70,
          top: widget.position.dy - 70,
          width: 140,
          height: 140,
          child: IgnorePointer(
            child: Stack(alignment: Alignment.center, children: [
              ...List.generate(9, (i) {
                final d = _dirs[i];
                return Opacity(
                  opacity: (1 - p).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(d.dx * p, d.dy * p + 72 * p * p),
                    child: Text(_coins[i], style: TextStyle(fontSize: 13 + (i % 3) * 3.0)),
                  ),
                );
              }),
              Transform.translate(
                offset: Offset(0, -48 * p),
                child: Opacity(
                  opacity: (1 - p * p).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xE64E9A3D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
                    ),
                    child: Text(
                      '+${formatIqd(widget.income)}  +${widget.xp} XP',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ═══════════════════════ ويدجتس مساعدة ═══════════════════════

class _Entrance extends StatelessWidget {
  const _Entrance({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final scale = 0.55 + 0.45 * Curves.easeOutBack.transform(p);
    return Opacity(opacity: p, child: Transform.scale(scale: scale, child: child));
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.tint,
  });

  final String icon;
  final String label;
  final String value;
  final double progress;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Transform.scale(
      scale: 0.7 + 0.3 * Curves.easeOutBack.transform(p),
      child: Opacity(
        opacity: p,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(.95), tint.withOpacity(.22)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.soilDark, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                '$label ',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: tint.withOpacity(1).withRed((tint.red * .6).round())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyPill extends StatelessWidget {
  const _ReadyPill({required this.count, required this.now});

  final int count;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final pulse = 1 + math.sin(now.millisecondsSinceEpoch / 280) * 0.07;
    final ready = count > 0;
    return Transform.scale(
      scale: ready ? pulse : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: ready ? const [Color(0xFF66BB6A), Color(0xFF43A047)] : [Colors.white.withOpacity(.7), Colors.white.withOpacity(.7)],
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: ready ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E), width: 1.5),
          boxShadow: ready ? const [BoxShadow(color: Color(0x6643A047), blurRadius: 8)] : null,
        ),
        child: Text(
          ready ? '✅ $count جاهز' : '⏳ لا حصاد بعد',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11.5,
            color: ready ? Colors.white : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }
}
