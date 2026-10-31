import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// استورد شاشاتك هنا
import '../farm/screens/farm_screen.dart';
import '../market/screens/market_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../shop/screens/shop_hub_screen.dart';
import '../profile/profile_screen.dart';
import '../game/state/game_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.firebaseReady = true});
  final bool firebaseReady;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  int _profileRevision = 0;

  void _openProfile() {
    HapticFeedback.lightImpact();
    setState(() {
      _index = 4;
      _profileRevision++;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      try {
        context.read<GameState>().flushSave();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    
    final pages = <Widget>[
      const FarmScreen(),
      const ShopHubScreen(),
      const MarketScreen(),
      const InventoryScreen(),
      ProfileScreen(key: ValueKey<int>(_profileRevision), firebaseReady: widget.firebaseReady),
    ];

    return Scaffold(
      extendBody: true, // ضروري لجعل الـ Bottom Nav يطفو فوق المحتوى
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4F7F6), // أبيض مائل للرمادي المخضر
              Color(0xFFE8F0ED), // أخضر فاتح جداً
              Color(0xFFDCE8E4), 
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Bar المطور
              ModernTopBar(onProfileTap: _openProfile),
              
              // 2. شريط التنبيه الأمني المطور (إذا وجد)
              if (gameState.legacyUnverified)
                const PremiumWarningBanner()
                  .animate()
                  .slideY(begin: -0.5, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                  .fade(duration: 600.ms),

              // 3. المحتوى الرئيسي مع أنيميشن انتقال ناعم
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<int>(_index),
                      child: pages[_index],
                    ),
                  ),
                ),
              ),
              
              // مساحة فارغة لضمان عدم تغطية المحتوى للـ Bottom Nav
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      // 4. شريط التنقل السفلي الزجاجي العائم
      bottomNavigationBar: ModernGlassBottomNav(
        index: _index,
        onChanged: (i) {
          HapticFeedback.selectionClick(); // اهتزاز خفيف جداً عند الاختيار
          setState(() => _index = i);
        },
      ),
    );
  }
}

// ==========================================
// ويدجت 1: شريط علوي عصري (Modern Top Bar)
// ==========================================
class ModernTopBar extends StatelessWidget {
  final VoidCallback onProfileTap;
  const ModernTopBar({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً بك 👋',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'مزرعتك بانتظارك',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  color: const Color(0xFF1B4332), // أخضر غامق فاخر
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2D6A4F),
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ويدجت 2: شريط تنبيه فاخر (Premium Warning)
// ==========================================
class PremiumWarningBanner extends StatelessWidget {
  const PremiumWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD166).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFE09F3E), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'حسابك القديم قيد المراجعة الأمنية. تم حفظ تقدمك بأمان، وسيتم تفعيل كافة العمليات قريباً.',
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A403A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ويدجت 3: شريط تنقل سفلي زجاجي (Glass Bottom Nav)
// ==========================================
class ModernGlassBottomNav extends StatelessWidget {
  final int index;
  final Function(int) onChanged;

  const ModernGlassBottomNav({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItem(icon: Icons.grass_rounded, label: 'المزرعة'),
      _NavItem(icon: Icons.storefront_rounded, label: 'المتجر'),
      _NavItem(icon: Icons.trending_up_rounded, label: 'السوق'),
      _NavItem(icon: Icons.inventory_2_rounded, label: 'المخزون'),
      _NavItem(icon: Icons.person_rounded, label: 'حسابي'),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65), // شفافية زجاجية
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final isSelected = index == i;
                  return GestureDetector(
                    onTap: () => onChanged(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 16 : 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2D6A4F) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF2D6A4F).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            items[i].icon,
                            color: isSelected ? Colors.white : const Color(0xFF52796F),
                            size: 24,
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              items[i].label,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}