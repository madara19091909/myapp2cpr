import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// شريط تنقل سفلي خفيف بأسلوب حديث، مع وجهات رئيسية فقط.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<_NavItem> _items = [
    _NavItem(Icons.grass_rounded, 'المزرعة'),
    _NavItem(Icons.storefront_rounded, 'المتجر'),
    _NavItem(Icons.store_rounded, 'السوق'),
    _NavItem(Icons.inventory_2_rounded, 'المخزن'),
    _NavItem(Icons.person_rounded, 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F5).withValues(alpha: .97),
          border: const Border(top: BorderSide(color: Color(0xFFE5E9E1))),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                return Expanded(
                  child: _NavButton(
                    item: item,
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                );
              }),
            ),
          ),
        ),
      );
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE5F1E2) : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 190),
                    width: selected ? 34 : 30,
                    height: selected ? 29 : 27,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFD3E9CF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.icon, size: 21, color: selected ? const Color(0xFF397846) : AppColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected ? const Color(0xFF397846) : const Color(0xFF7C857A),
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
