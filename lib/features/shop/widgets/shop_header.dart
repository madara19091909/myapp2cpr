import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shared, responsive header for shop pages.
class ShopHeader extends StatelessWidget {
  const ShopHeader({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.count,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFEFC8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 21, height: 1.15, fontWeight: FontWeight.w900, color: AppColors.dark)),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(14)),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }
}

class ShopSearchField extends StatelessWidget {
  const ShopSearchField({super.key, required this.onChanged, this.hint = 'ابحث عن عنصر...'});

  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: const Icon(Icons.tune_rounded),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class ShopEmptyState extends StatelessWidget {
  const ShopEmptyState({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .8), borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.outline)),
    child: Column(children: [
      const Text('🔎', style: TextStyle(fontSize: 42)),
      const SizedBox(height: 8),
      const Text('ما لقينا نتائج', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.dark)),
      const SizedBox(height: 4),
      Text('جرّب كلمة ثانية بدل «$query»', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
    ]),
  );
}
