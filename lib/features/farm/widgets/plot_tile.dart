import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../game/models/plot.dart';
import '../../shop/data/shop_data.dart';

class PlotTile extends StatelessWidget {
  const PlotTile({super.key, required this.plot, required this.now, required this.onTap, this.onWater});

  final Plot plot;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback? onWater;

  @override
  Widget build(BuildContext context) {
    final crop = plot.isEmpty ? null : ShopData.tryCropById(plot.cropId!);
    final ready = crop != null && plot.isReady(now);
    final remaining = plot.remainingSeconds(now);
    final progress = crop == null || plot.growSeconds <= 0
        ? 0.0
        : (1 - remaining / plot.growSeconds).clamp(0.0, 1.0).toDouble();
    final label = crop == null
        ? 'أرض فارغة، اضغط لاختيار بذور'
        : ready
            ? '${crop.name} جاهز للحصاد، اضغط للحصاد'
            : '${crop.name} ينمو، الوقت المتبقي ${formatDuration(remaining)}';

    return Semantics(
      button: true,
      label: label,
      hint: crop == null ? 'يفتح قائمة البذور' : ready ? 'يحصد المحصول' : 'يعرض الوقت المتبقي',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = math.min(constraints.maxWidth, constraints.maxHeight).toDouble();
              final symbol = crop == null ? '➕' : ready ? crop.emoji : progress < .5 ? '🌱' : '🌿';
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ready
                        ? const [Color(0xFFE8B85D), Color(0xFFB7792D)]
                        : const [Color(0xFFC99155), AppColors.soil],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ready ? AppColors.gold : AppColors.soilDark, width: ready ? 3 : 2),
                  boxShadow: [
                    BoxShadow(
                      color: ready ? AppColors.gold.withValues(alpha: .65) : const Color(0x33000000),
                      offset: const Offset(0, 4),
                      blurRadius: ready ? 8 : 3,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: AnimatedScale(
                        scale: ready ? 1.08 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: Opacity(
                          opacity: crop == null ? .65 : 1,
                          child: Text(symbol, style: TextStyle(fontSize: size * (ready ? .48 : .40))),
                        ),
                      ),
                    ),
                    if (crop != null && !ready && !plot.watered)
                      Positioned(
                        top: 3,
                        left: 3,
                        child: Material(
                          color: const Color(0xFFB3E5FC),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onWater,
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.water_drop, size: 16, color: Color(0xFF075985)),
                            ),
                          ),
                        ),
                      ),
                    if (crop != null && plot.watered && !ready)
                      const Positioned(
                        top: 5,
                        left: 6,
                        child: Text('💧', style: TextStyle(fontSize: 14)),
                      ),
                    if (ready)
                      const Positioned(
                        top: 5,
                        right: 7,
                        child: Text('✨', style: TextStyle(fontSize: 17)),
                      ),
                    if (crop != null && !ready)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 7,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatDuration(remaining),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, shadows: AppTheme.outline),
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
                    if (ready)
                      Positioned(
                        bottom: 7,
                        left: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                          decoration: BoxDecoration(color: const Color(0xCC2E7D32), borderRadius: BorderRadius.circular(9)),
                          child: const Text(
                            'احصد الآن',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
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
    );
  }
}
