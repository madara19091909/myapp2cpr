import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../farm/screens/farm_screen.dart';
import '../market/screens/market_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../shop/screens/shop_hub_screen.dart';
import '../profile/profile_screen.dart';
import '../game/state/game_state.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/top_bar.dart';

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
      // حفظ نسخة كاش محلية فقط؛ الحالة المعتمدة موجودة على الخادم
      try {
        context.read<GameState>().flushSave();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const FarmScreen(),
      const ShopHubScreen(),
      const MarketScreen(),
      const InventoryScreen(),
      ProfileScreen(key: ValueKey<int>(_profileRevision), firebaseReady: widget.firebaseReady),
    ];
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF2), Color(0xFFFFEFC8), Color(0xFFFFE4A8)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Column(
          children: [
            TopBar(onProfileTap: _openProfile),
            if (context.watch<GameState>().legacyUnverified)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8C2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB7791F)),
                ),
                child: const Text(
                  'حسابك القديم قيد المراجعة الأمنية. تم حفظ تقدمك، لكن عمليات المزرعة والشراء والبيع والمكافآت متوقفة مؤقتاً حتى يراجع الأدمن الأرصدة القديمة ويعتمد الحساب.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF704214)),
                ),
              ),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(index: _index, onChanged: (i) => setState(() => _index = i)),
    );
  }
}
