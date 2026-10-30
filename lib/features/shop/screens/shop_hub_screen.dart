import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../buildings/screens/buildings_screen.dart';
import 'animals_screen.dart';
import 'seeds_screen.dart';
import 'tools_screen.dart';

/// يجمع أقسام المتجر في مساحة واحدة بدلاً من أزرار منفصلة في الشريط السفلي.
class ShopHubScreen extends StatelessWidget {
  const ShopHubScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(12, 9, 12, 8),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7E8E1))),
              child: TabBar(
                isScrollable: false,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: const Color(0xFFE6F3E2), borderRadius: BorderRadius.circular(13)),
                labelColor: const Color(0xFF397846),
                unselectedLabelColor: AppColors.muted,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                tabs: const [
                  Tab(icon: Icon(Icons.grass_rounded, size: 19), text: 'البذور'),
                  Tab(icon: Icon(Icons.pets_rounded, size: 19), text: 'الحيوانات'),
                  Tab(icon: Icon(Icons.handyman_rounded, size: 19), text: 'الأدوات'),
                  Tab(icon: Icon(Icons.home_work_rounded, size: 19), text: 'المباني'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [SeedsScreen(), AnimalsScreen(), ToolsScreen(), BuildingsScreen()],
              ),
            ),
          ],
        ),
      );
}
