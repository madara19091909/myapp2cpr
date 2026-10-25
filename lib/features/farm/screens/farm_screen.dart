import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../widgets/plot_tile.dart';
import '../widgets/seed_picker.dart';
import '../widgets/particle_system.dart';
import '../widgets/achievement_popup.dart';
import '../services/sound_service.dart';

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> with TickerProviderStateMixin {
  late AnimationController _timeController;
  late AnimationController _parallaxController;
  late SoundService _soundService;
  
  @override
  void initState() {
    super.initState();
    _soundService = SoundService();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timeController.dispose();
    _parallaxController.dispose();
    _soundService.dispose();
    super.dispose();
  }

  Future<void> _handlePlotTap(BuildContext context, int index) async {
    final gameState = context.read<GameState>();
    final plot = gameState.plots[index];
    final now = DateTime.now();

    if (plot.isEmpty) {
      await _handleEmptyPlot(context, index);
      return;
    }

    if (plot.isReady(now)) {
      await _handleHarvest(context, index, gameState);
      return;
    }

    _handleUnripePlot();
  }

  Future<void> _handleEmptyPlot(BuildContext context, int index) async {
    _soundService.playTap();
    HapticFeedback.selectionClick();
    
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SeedPicker(plotIndex: index),
    );
  }

  Future<void> _handleHarvest(
    BuildContext context,
    int index,
    GameState gameState,
  ) async {
    // اهتزاز قوي ومُرضي
    await HapticFeedback.heavyImpact();
    _soundService.playHarvest();

    final result = gameState.harvest(index);
    if (result != null) {
      // تأثير الجسيمات المتقدم
      _showHarvestParticles(context, index);
      
      // التحقق من الإنجازات
      await _checkAchievements(context, gameState, result);

      // رسالة النجاح المحسنة
      final levelUpMsg = result.levelsGained > 0
          ? '\n🎉 مستوى جديد: ${gameState.level}! +${result.levelsGained * GameState.levelUpGoldReward} 🪙'
          : '';

      _showSuccessToast(
        context,
        '+${formatIqd(result.income)}  •  +${result.xp} XP$levelUpMsg',
      );
    }
  }

  void _showHarvestParticles(BuildContext context, int index) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // إظهار عملات متطايرة
    ParticleSystem.show(
      context: context,
      particleType: ParticleType.coins,
      count: 20,
      origin: Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    // إظهار نجوم متلألئة
    ParticleSystem.show(
      context: context,
      particleType: ParticleType.stars,
      count: 15,
      origin: Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
  }

  Future<void> _checkAchievements(
    BuildContext context,
    GameState gameState,
    dynamic result,
  ) async {
    // تحقق من الإنجازات
    if (gameState.level > 5 && !gameState.hasShownLevel5Achievement) {
      AchievementPopup.show(
        context,
        title: 'إنجاز رائع!',
        description: 'وصلت للمستوى 5!',
        icon: Icons.emoji_events,
        color: Colors.amber,
      );
      gameState.hasShownLevel5Achievement = true;
    }

    if (result.income > 1000 && !gameState.hasShownRichAchievement) {
      AchievementPopup.show(
        context,
        title: 'ثروة!',
        description: 'حصلت على أكثر من 1000 في حصاد واحد!',
        icon: Icons.attach_money,
        color: Colors.green,
      );
      gameState.hasShownRichAchievement = true;
    }
  }

  void _showSuccessToast(BuildContext context, String message) {
    showToast(
      context,
      message,
      color: AppColors.green,
      icon: Icons.eco,
      duration: const Duration(seconds: 3),
    );
  }

  void _handleUnripePlot() {
    _soundService.playError();
    HapticFeedback.lightImpact();
    showToast(
      context,
      'المحصول لم ينضج بعد ⏳',
      color: Colors.orangeAccent,
      icon: Icons.hourglass_empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 600 ? 4 : 3;

    return Scaffold(
      body: _DynamicBackground(
        timeController: _timeController,
        child: SafeArea(
          child: Column(
            children: [
              _PremiumFarmHeader(
                parallaxController: _parallaxController,
                timeController: _timeController,
              ),
              _StatsBar(
                speedFactor: gameState.speedFactor,
                yieldMultiplier: gameState.yieldMultiplier,
                petBonus: gameState.petBonusPercent,
              ),
              _SectionTitle(totalPlots: gameState.plots.length),
              Expanded(
                child: _OptimizedFarmGrid(
                  plots: gameState.plots,
                  crossAxisCount: crossAxisCount,
                  onTap: (i) => _handlePlotTap(context, i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ==========================================
/// 1. الخلفية الديناميكية (نهار/ليل)
/// ==========================================
class _DynamicBackground extends StatelessWidget {
  final AnimationController timeController;
  final Widget child;

  const _DynamicBackground({
    required this.timeController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timeController,
      builder: (context, _) {
        final timeOfDay = timeController.value;
        final colors = _getGradientColors(timeOfDay);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
    );
  }

  List<Color> _getGradientColors(double timeOfDay) {
    // 0.0 - 0.25: فجر
    // 0.25 - 0.5: نهار
    // 0.5 - 0.75: غروب
    // 0.75 - 1.0: ليل

    if (timeOfDay < 0.25) {
      return [
        const Color(0xFFFFB347), // برتقالي
        const Color(0xFFFFCC80), // أصفر فاتح
        const Color(0xFF81C784), // أخضر
      ];
    } else if (timeOfDay < 0.5) {
      return [
        const Color(0xFF4FC3F7), // أزرق فاتح
        const Color(0xFFB3E5FC), // أزرق سماوي
        const Color(0xFF66BB6A), // أخضر
      ];
    } else if (timeOfDay < 0.75) {
      return [
        const Color(0xFFFF7043), // برتقالي غروب
        const Color(0xFFFFAB91), // وردي
        const Color(0xFF5C6BC0), // بنفسجي
      ];
    } else {
      return [
        const Color(0xFF1A237E), // أزرق داكن
        const Color(0xFF283593), // نيلي
        const Color(0xFF1B5E20), // أخضر داكن
      ];
    }
  }
}

/// ==========================================
/// 2. الهيدر مع تأثير Parallax
/// ==========================================
class _PremiumFarmHeader extends StatelessWidget {
  final AnimationController parallaxController;
  final AnimationController timeController;

  const _PremiumFarmHeader({
    required this.parallaxController,
    required this.timeController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5A15).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية متدرجة
          _AnimatedSkyBackground(timeController: timeController),

          // نجوم ليلية
          AnimatedBuilder(
            animation: timeController,
            builder: (context, _) {
              final showStars = timeController.value > 0.75;
              return showStars
                  ? const _StarField()
                  : const SizedBox.shrink();
            },
          ),

          // الشمس/القمر
          _CelestialBody(timeController: timeController),

          // السحب المتحركة مع Parallax
          AnimatedBuilder(
            animation: parallaxController,
            builder: (context, _) {
              final offset = parallaxController.value * 30;
              return Stack(
                children: [
                  Positioned(
                    top: 30,
                    left: 20 + offset,
                    child: _AnimatedCloud(size: 50, duration: 15),
                  ),
                  Positioned(
                    top: 50,
                    right: 80 - offset,
                    child: _AnimatedCloud(size: 35, duration: 20),
                  ),
                  Positioned(
                    top: 70,
                    left: 120 + offset * 0.5,
                    child: _AnimatedCloud(size: 40, duration: 18),
                  ),
                ],
              );
            },
          ),

          // الأرضية والمزرعة
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6B4226),
                    const Color(0xFF4A2E1B),
                  ],
                ),
              ),
            ),
          ),

          // بطاقة العنوان (Glassmorphism)
          Positioned(
            top: 16,
            left: 16,
            child: _GlassCard(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.agriculture, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'مزرعتي',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شارة الوقت
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedBuilder(
              animation: timeController,
              builder: (context, _) {
                final timeText = _getTimeText(timeController.value);
                return _GlassCard(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTimeIcon(timeController.value), 
                           color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeText(double timeOfDay) {
    if (timeOfDay < 0.25) return 'فجر';
    if (timeOfDay < 0.5) return 'نهار';
    if (timeOfDay < 0.75) return 'غروب';
    return 'ليل';
  }

  IconData _getTimeIcon(double timeOfDay) {
    if (timeOfDay < 0.25) return Icons.wb_twilight;
    if (timeOfDay < 0.5) return Icons.wb_sunny;
    if (timeOfDay < 0.75) return Icons.wb_twilight;
    return Icons.nightlight_round;
  }
}

/// ==========================================
/// 3. السماء المتحركة
/// ==========================================
class _AnimatedSkyBackground extends StatelessWidget {
  final AnimationController timeController;

  const _AnimatedSkyBackground({required this.timeController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timeController,
      builder: (context, _) {
        final timeOfDay = timeController.value;
        final colors = _getSkyColors(timeOfDay);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: const [0.0, 0.6, 0.61],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getSkyColors(double timeOfDay) {
    if (timeOfDay < 0.25) {
      return [
        const Color(0xFFFFB347),
        const Color(0xFFFFCC80),
        const Color(0xFF81C784),
      ];
    } else if (timeOfDay < 0.5) {
      return [
        const Color(0xFF4FC3F7),
        const Color(0xFF88D4A1),
        const Color(0xFF5C9E31),
      ];
    } else if (timeOfDay < 0.75) {
      return [
        const Color(0xFFFF7043),
        const Color(0xFFFFAB91),
        const Color(0xFF5C6BC0),
      ];
    } else {
      return [
        const Color(0xFF1A237E),
        const Color(0xFF283593),
        const Color(0xFF1B5E20),
      ];
    }
  }
}

/// ==========================================
/// 4. حقل النجوم
/// ==========================================
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(),
      child: Container(),
    ).animate(onPlay: (c) => c.repeat()).opacity(
          begin: 0.3,
          end: 1.0,
          duration: 2000.ms,
        );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final radius = random.nextDouble() * 2 + 1;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ==========================================
/// 5. الشمس/القمر
/// ==========================================
class _CelestialBody extends StatelessWidget {
  final AnimationController timeController;

  const _CelestialBody({required this.timeController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timeController,
      builder: (context, _) {
        final timeOfDay = timeController.value;
        final isNight = timeOfDay > 0.75;

        return Positioned(
          top: 20 + (math.sin(timeOfDay * math.pi * 2) * 20),
          right: 30,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isNight
                    ? [Colors.grey.shade200, Colors.grey.shade400]
                    : [Colors.yellow.shade200, Colors.orange.shade300],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isNight ? Colors.grey : Colors.yellow)
                      .withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
          ).animate(onPlay: (c) => c.repeat()).scaleXY(
                begin: 1.0,
                end: 1.1,
                duration: 2000.ms,
              ),
        );
      },
    );
  }
}

/// ==========================================
/// 6. البطاقة الزجاجية
/// ==========================================
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ==========================================
/// 7. السحابة المتحركة
/// ==========================================
class _AnimatedCloud extends StatelessWidget {
  final double size;
  final int duration;

  const _AnimatedCloud({required this.size, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(size),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 10,
          )
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).translateX(
          begin: -10,
          end: 10,
          duration: (duration * 1000).ms,
        );
  }
}

/// ==========================================
/// 8. شريط الإحصائيات المتقدم
/// ==========================================
class _StatsBar extends StatelessWidget {
  final double speedFactor;
  final int yieldMultiplier;
  final int petBonus;

  const _StatsBar({
    required this.speedFactor,
    required this.yieldMultiplier,
    required this.petBonus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AnimatedStatBadge(
                  icon: Icons.bolt,
                  value: (1 / speedFactor).toStringAsFixed(1),
                  prefix: '×',
                  color: Colors.amber,
                  label: 'سرعة',
                ),
                _AnimatedStatBadge(
                  icon: Icons.grain,
                  value: yieldMultiplier.toString(),
                  prefix: '×',
                  color: Colors.green,
                  label: 'حصاد',
                ),
                _AnimatedStatBadge(
                  icon: Icons.pets,
                  value: petBonus.toString(),
                  prefix: '+',
                  suffix: '%',
                  color: Colors.pink,
                  label: 'حيوانات',
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }
}

/// ==========================================
/// 9. شارة الإحصائيات المتحركة
/// ==========================================
class _AnimatedStatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String prefix;
  final String suffix;
  final Color color;
  final String label;

  const _AnimatedStatBadge({
    required this.icon,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix$value$suffix',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// ==========================================
/// 10. عنوان القسم
/// ==========================================
class _SectionTitle extends StatelessWidget {
  final int totalPlots;
  const _SectionTitle({required this.totalPlots});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'حقول المزرعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B3A12),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              '$totalPlots قطعة',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E5C1A),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================================
/// 11. الشبكة المحسنة
/// ==========================================
class _OptimizedFarmGrid extends StatelessWidget {
  final List<dynamic> plots;
  final int crossAxisCount;
  final void Function(int) onTap;

  const _OptimizedFarmGrid({
    required this.plots,
    required this.crossAxisCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: plots.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        return PlotTile(
          plot: plots[i],
          onTap: () => onTap(i),
        ).animate().fadeIn(
              delay: (50 * i).ms,
              duration: 400.ms,
            ).scaleXY(
              begin: 0.8,
              end: 1.0,
            );
      },
    );
  }
}