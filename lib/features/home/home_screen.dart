import 'package:flutter/material.dart';

import '../buildings/screens/buildings_screen.dart';
import '../farm/screens/farm_screen.dart';
import '../market/screens/market_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../shop/screens/animals_screen.dart';
import '../shop/screens/seeds_screen.dart';
import '../shop/screens/tools_screen.dart';
import '../social/social_screen.dart';
import '../progression/screens/progression_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.firebaseReady = true});

  final bool firebaseReady;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const FarmScreen(),
      const SeedsScreen(),
      const AnimalsScreen(),
      const ToolsScreen(),
      const BuildingsScreen(),
      const InventoryScreen(),
      const MarketScreen(),
      SocialScreen(firebaseReady: widget.firebaseReady),
      const ProgressionScreen(),
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
            const TopBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey<int>(_index), child: pages[_index]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(index: _index, onChanged: (i) => setState(() => _index = i)),
    );
  }
}
