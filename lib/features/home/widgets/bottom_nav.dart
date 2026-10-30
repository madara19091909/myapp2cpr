import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<(String, String)> _items = [
    ('🌾', 'المزرعة'),
    ('🌱', 'البذور'),
    ('🐄', 'الحيوانات'),
    ('🛠️', 'الأدوات'),
    ('🏗️', 'المباني'),
    ('🎒', 'المخزن'),
    ('🏪', 'السوق'),
    ('👥', 'الأصدقاء'),
    ('🎯', 'المهام'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA06B38), AppColors.woodDeep],
        ),
        border: Border(top: BorderSide(color: AppColors.soilDark, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) => SizedBox(
              width: 70,
              child: _NavButton(
                emoji: _items[i].$1,
                label: _items[i].$2,
                selected: i == index,
                onTap: () => onChanged(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          margin: EdgeInsets.fromLTRB(2, selected ? 0 : 5, 2, selected ? 3 : 0),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9BE86A), AppColors.grassDeep],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? Border.all(color: const Color(0xFF1B5E20), width: 3)
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(color: Color(0xFF1B5E20), offset: Offset(0, 4)),
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.28 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: selected ? 11 : 10,
                    shadows: selected ? AppTheme.outline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
