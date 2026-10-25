import 'package:flutter/material.dart';

import '../farm/screens/farm_screen.dart';
import '../market/screens/market_screen.dart';
import '../shop/screens/animals_screen.dart';
import '../shop/screens/seeds_screen.dart';
import '../shop/screens/tools_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    FarmScreen(),
    SeedsScreen(),
    AnimalsScreen(),
    ToolsScreen(),
    MarketScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: _pages[_index],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
