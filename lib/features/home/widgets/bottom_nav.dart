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
          colors: [AppColors.wood, Color(0xFF6B4220)],
        ),
        border: Border(top: BorderSide(color: AppColors.soilDark, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 5, 3, 6),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavButton(
                    emoji: _items[i].$1,
                    label: _items[i].$2,
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.emoji, required this.label, required this.selected, required this.onTap});

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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        margin: EdgeInsets.fromLTRB(3, selected ? 0 : 4, 3, selected ? 4 : 0),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8BE05A), AppColors.green],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: selected ? Border.all(color: const Color(0xFF2E7D32), width: 3) : null,
          boxShadow: selected
              ? const [BoxShadow(color: Color(0xFF2E7D32), offset: Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.25 : 1,
              duration: const Duration(milliseconds: 220),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    shadows: selected ? AppTheme.outline : null,
                  )),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
