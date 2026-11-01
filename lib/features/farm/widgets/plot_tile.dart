import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../game/models/plot.dart';
import '../../shop/data/shop_data.dart';

class PlotTile extends StatelessWidget {
  const PlotTile({
    super.key,
    required this.plot,
    required this.now,
    required this.onTap,
    this.onWater,
  });

  final Plot plot;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback? onWater;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final crop = plot.isEmpty ? null : ShopData.tryCropById(plot.cropId!);
    final ready = crop != null && plot.isReady(now);
    final growing = crop != null && !ready;
    final remaining = plot.remainingSeconds(now);
    final progress = crop == null || plot.growSeconds <= 0
        ? 0.0
        : (1 - remaining / plot.growSeconds).clamp(0.0, 1.0).toDouble();

    final label = crop == null
        ? 'أرض فارغة، اضغط لاختيار بذور'
        : ready
            ? '${crop.name} جاهز للحصاد، اضغط للحصاد'
            : '${crop.name} ينمو، الوقت المتبقي ${formatDuration(remaining)}';

    final symbol = crop == null
        ? ''
        : ready
            ? crop.emoji
            : progress < .34
                ? '🌱'
                : progress < .75
                    ? '🌿'
                    : '🌾';

    return RepaintBoundary(
      child: Semantics(
        container: true,
        button: true,
        label: label,
        hint: crop == null ? 'يفتح قائمة البذور' : ready ? 'يحصد المحصول' : 'يعرض الوقت المتبقي',
        child: ExcludeSemantics(
          child: _Pulse(
            active: ready,
            builder: (context, t) => LayoutBuilder(
              builder: (context, constraints) {
                final size = math.min(constraints.maxWidth, constraints.maxHeight).toDouble();

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: ready
                          ? const [Color(0xFFF7D98E), Color(0xFFD7A34F)]
                          : crop == null
                              ? const [Color(0xFFB98D65), Color(0xFF936A4B)]
                              : const [Color(0xFFB58A5D), Color(0xFF805A3C)],
                    ),
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(
                      color: ready ? const Color(0xFFE8B84E) : const Color(0xFFE6C6A3),
                      width: ready ? 2.2 : 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ready
                            ? AppColors.gold.withValues(alpha: .30 + .25 * t)
                            : const Color(0x252B3F2D),
                        offset: const Offset(0, 5),
                        blurRadius: ready ? 10 + 4 * t : 9,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Empty plots use a clear, soft planting action instead of a huge plus glyph.
                      Center(
                        child: crop == null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: size * .42,
                                    height: size * .42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .18),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: .38), width: 1.3),
                                    ),
                                    child: Icon(Icons.add_rounded, color: Colors.white, size: size * .27),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'ازرع هنا',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      shadows: [Shadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 1))],
                                    ),
                                  ),
                                ],
                              )
                            : AnimatedScale(
                                scale: ready ? 1.06 + .04 * t : 1,
                                duration: const Duration(milliseconds: 200),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) => ScaleTransition(
                                    scale: anim,
                                    child: FadeTransition(opacity: anim, child: child),
                                  ),
                                  child: Text(
                                    symbol,
                                    key: ValueKey(symbol),
                                    style: TextStyle(fontSize: size * (ready ? .48 : .40)),
                                  ),
                                ),
                              ),
                      ),

                      // طبقة اللمس (فوق المحتوى حتى يبين الـ ripple)
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                        ),
                      ),

                      // زر السقي
                      if (growing && !plot.watered)
                        Positioned(
                          top: 2,
                          left: 2,
                          child: Semantics(
                            button: true,
                            label: 'سقي المحصول',
                            child: Material(
                              color: const Color(0xFFB3E5FC),
                              shape: const CircleBorder(),
                              elevation: 1,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onWater,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.water_drop, size: 16, color: Color(0xFF075985)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (growing && plot.watered)
                        const Positioned(
                          top: 5,
                          left: 6,
                          child: Text('💧', style: TextStyle(fontSize: 14)),
                        ),

                      // نجمة الجاهزية
                      if (ready)
                        Positioned(
                          top: 5,
                          right: 7,
                          child: IgnorePointer(
                            child: Transform.scale(
                              scale: 1 + .25 * t,
                              child: const Text('✨', style: TextStyle(fontSize: 17)),
                            ),
                          ),
                        ),

                      // الوقت + شريط التقدم
                      if (growing)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 7,
                          child: IgnorePointer(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    formatDuration(remaining),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      shadows: AppTheme.outline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: Colors.black26,
                                    color: const Color(0xFFB8F55B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // شارة "احصد الآن"
                      if (ready)
                        Positioned(
                          bottom: 7,
                          left: 6,
                          right: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xCC2E7D32),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'احصد الآن',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// نبض خفيف (0 → 1 → 0). يشتغل فقط لمن يكون `active` = true.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.builder});

  final bool active;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _Pulse old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
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
      builder: (context, _) => widget.builder(context, Curves.easeInOut.transform(_c.value)),
    );
  }
}