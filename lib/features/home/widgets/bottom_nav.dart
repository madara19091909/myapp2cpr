import 'package:flutter/material.dart';

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
      color: const Color(0xFFFDFEFC).withValues(alpha: .97),
      border: const Border(top: BorderSide(color: Color(0xFFE3E9E1))),
      boxShadow: const [BoxShadow(color: Color(0x120F2816), blurRadius: 22, offset: Offset(0, -6))],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
        child: Row(children: List.generate(_items.length, (i) {
          final item = _items[i];
          return Expanded(child: _NavButton(item: item, selected: i == index, onTap: () => onChanged(i)));
        })),
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
    button: true, selected: selected, label: item.label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F2E7) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42, height: 31,
            decoration: BoxDecoration(color: selected ? const Color(0xFFD3E9D6) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, size: 21, color: selected ? const Color(0xFF28633D) : const Color(0xFF8A9389)),
          ),
          const SizedBox(height: 3),
          Text(item.label, maxLines: 1, style: TextStyle(color: selected ? const Color(0xFF28633D) : const Color(0xFF858D84), fontWeight: selected ? FontWeight.w900 : FontWeight.w600, fontSize: 10)),
        ]),
      ),
    ),
  );
}
