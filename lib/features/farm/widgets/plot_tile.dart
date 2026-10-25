import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../game/models/plot.dart';
import '../../shop/data/shop_data.dart';

class PlotTile extends StatelessWidget {
  const PlotTile({super.key, required this.plot, required this.now, required this.onTap});

  final Plot plot;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final crop = plot.isEmpty ? null : ShopData.cropById(plot.cropId!);
    final ready = crop != null && plot.isReady(now);
    final remaining = plot.remainingSeconds(now);
    final progress = (crop == null || plot.growSeconds == 0)
        ? 0.0
        : (1 - remaining / plot.growSeconds).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, c) {
          final size = math.min(c.maxWidth, c.maxHeight);
          String symbol;
          if (crop == null) {
            symbol = '➕';
          } else if (ready) {
            symbol = crop.emoji;
          } else {
            symbol = progress < .5 ? '🌱' : '🌿';
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC48B4B), AppColors.soil],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ready ? AppColors.gold : AppColors.soilDark, width: 4),
              boxShadow: [
                BoxShadow(
                  color: ready ? AppColors.gold.withOpacity(.7) : AppColors.soilDark,
                  offset: const Offset(0, 5),
                  blurRadius: ready ? 10 : 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: crop == null ? .45 : 1,
                    child: Text(symbol, style: TextStyle(fontSize: size * (ready ? .5 : .42))),
                  ),
                ),
                if (ready)
                  Positioned(
                    top: 4,
                    right: 6,
                    child: Text('✨', style: TextStyle(fontSize: size * .2)),
                  ),
                if (crop != null && !ready)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Text(
                            formatDuration(remaining),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              shadows: AppTheme.outline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: Colors.black26,
                            color: AppColors.grass,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
