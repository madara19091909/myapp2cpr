import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../widgets/seed_picker.dart';

// ==========================================
// الشاشة الرئيسية: مزرعة بمستوى ألعاب AAA (مصححة)
// ==========================================
class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> with TickerProviderStateMixin {
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _handlePlotTap(BuildContext context, int index) async {
    final gameState = context.read<GameState>();
    final plot = gameState.plots[index];
    final now = DateTime.now();

    if (plot.isEmpty) {
      HapticFeedback.selectionClick();
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => SeedPicker(plotIndex: index),
      );
      return;
    }

    if (plot.isReady(now)) {
      HapticFeedback.mediumImpact();
      final result = gameState.harvest(index);
      if (result != null) {
        final levelUpMsg = result.levelsGained > 0
            ? '\n🎉 مستوى جديد: ${gameState.level}!'
            : '';
            
        showToast(
          context,
          '+${formatIqd(result.income)} دينار  •  +${result.xp} XP$levelUpMsg',
          color: const Color(0xFF2E7D32),
        );
      }
      return;
    }

    HapticFeedback.lightImpact();
    showToast(context, 'المحصول ينمو... انتظر قليلاً ⏳', color: Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 600 ? 4 : (width >= 400 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _PremiumGameHUD(gameState: gameState),
              const SizedBox(height: 16),
              Expanded(
                child: _OrganicFarmGrid(
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

// ==========================================
// 1. واجهة المعلومات العلوية (Game HUD)
// ==========================================
class _PremiumGameHUD extends StatelessWidget {
  final GameState gameState;
  const _PremiumGameHUD({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // شارة المستوى
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA000).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${gameState.level}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // معلومات اللاعب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رصيدك',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.currency_exchange, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 4),
                      // ملاحظة: إذا كان اسم المتغير في GameState الخاص بك هو money أو iqd، غيّر gameState.gold إليه
                      Text(
                        formatIqd(gameState.gold), 
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // زر المكافآت اليومية
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.card_giftcard, color: Color(0xFFE65100), size: 28),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: -0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }
}

// ==========================================
// 2. شبكة المزرعة العضوية
// ==========================================
class _OrganicFarmGrid extends StatelessWidget {
  final List<dynamic> plots;
  final int crossAxisCount;
  final void Function(int) onTap;

  const _OrganicFarmGrid({
    required this.plots,
    required this.crossAxisCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: plots.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, i) {
        return _PremiumPlotTile(
          plot: plots[i],
          onTap: () => onTap(i),
        ).animate().fadeIn(delay: (80 * i).ms, duration: 500.ms).scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack);
      },
    );
  }
}

// ==========================================
// 3. الحقل الاحترافي (مصحح)
// ==========================================
class _PremiumPlotTile extends StatelessWidget {
  final dynamic plot;
  final VoidCallback onTap;

  const _PremiumPlotTile({required this.plot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isReady = plot.isReady != null ? plot.isReady(now) : false;
    final isEmpty = plot.isEmpty ?? true;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getPlotColors(isEmpty, isReady),
          ),
          boxShadow: [
            BoxShadow(
              color: _getShadowColor(isEmpty, isReady),
              blurRadius: isReady ? 20 : 12,
              offset: Offset(0, isReady ? 8 : 4),
            ),
            // تم إزالة inset: true لأنه غير مدعوم في Flutter BoxShadow
            // نعوض عنه بحدود خفيفة تعطي عمقاً
          ],
          border: Border.all(
            color: isReady ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.5),
            width: isReady ? 3 : 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              if (!isEmpty) const _SoilPattern(),
              
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlotIcon(isEmpty, isReady),
                    const SizedBox(height: 12),
                    _buildPlotText(isEmpty, isReady),
                    if (!isEmpty && !isReady) _buildGrowthBar(plot),
                  ],
                ),
              ),

              if (isReady)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat()).fade(begin: 0.3, end: 0.8, duration: 800.ms),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getPlotColors(bool isEmpty, bool isReady) {
    if (isEmpty) return const [Color(0xFFD7CCC8), Color(0xFFBCAAA4)];
    if (isReady) return const [Color(0xFF66BB6A), Color(0xFF43A047)];
    return const [Color(0xFF8D6E63), Color(0xFF6D4C41)];
  }

  Color _getShadowColor(bool isEmpty, bool isReady) {
    if (isEmpty) return Colors.black12;
    if (isReady) return const Color(0xFF43A047).withOpacity(0.4);
    return Colors.black26;
  }

  Widget _buildPlotIcon(bool isEmpty, bool isReady) {
    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Color(0xFF5D4037), size: 28),
      );
    }
    
    // تم التصحيح هنا: استبدال Icons.sprout بـ Icons.grass
    final icon = isReady ? Icons.eco : Icons.grass;
    final color = isReady ? Colors.white : const Color(0xFFA5D6A7);
    
    return Icon(icon, color: color, size: 48).animate(
      onPlay: (c) => isReady ? c.repeat(reverse: true) : c,
    ).scaleXY(begin: 1.0, end: 1.1, duration: 1000.ms);
  }

  Widget _buildPlotText(bool isEmpty, bool isReady) {
    if (isEmpty) {
      return const Text('فارغ', style: TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.w700, fontSize: 14));
    }
    if (isReady) {
      return const Text('جاهز للحصاد!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1))]));
    }
    return const Text('ينمو...', style: TextStyle(color: Color(0xFFE8F5E9), fontWeight: FontWeight.w600, fontSize: 13));
  }

  Widget _buildGrowthBar(dynamic plot) {
    // قيمة تجريبية، يمكنك ربطها بمنطق التقدم الفعلي في gameState
    const double progress = 0.65; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: Colors.black26,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)),
        ),
      ),
    );
  }
}

// ==========================================
// 4. نمط التربة
// ==========================================
class _SoilPattern extends StatelessWidget {
  const _SoilPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SoilPainter(),
      child: Container(),
    );
  }
}

class _SoilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}