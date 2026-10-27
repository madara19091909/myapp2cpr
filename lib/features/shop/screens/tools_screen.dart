import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../data/shop_data.dart';
import '../widgets/emoji_badge.dart';
import '../widgets/shop_header.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final tools = ShopData.tools.where((t) => '${t.name} ${t.id} ${t.emoji} ${t.description}'.toLowerCase().contains(_query.trim().toLowerCase())).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        ShopHeader(emoji: '🧰', title: 'متجر الأدوات', subtitle: 'أدوات دائمة تساعدك على تطوير أسلوب اللعب', count: ShopData.tools.length),
        ShopSearchField(hint: 'ابحث عن أداة أو ميزة...', onChanged: (value) => setState(() => _query = value)),
        if (tools.isEmpty) ShopEmptyState(query: _query),
        for (final t in tools)
          CartoonCard(
            child: Column(
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  EmojiBadge(t.emoji, size: 58),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark)),
                    const SizedBox(height: 4),
                    Text(t.description, style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    InfoChip('${t.goldPrice} 🪙', color: AppColors.gold),
                  ])),
                ]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: CartoonButton(
                  color: g.hasTool(t.id) ? AppColors.purple : AppColors.orange,
                  leading: g.hasTool(t.id) ? '✅' : '🪙',
                  label: g.hasTool(t.id) ? 'مملوكة بالفعل' : 'شراء الأداة • ${t.goldPrice} عملة',
                  onPressed: g.hasTool(t.id) ? null : () {
                    final err = context.read<GameState>().buyTool(t);
                    showToast(context, err ?? 'تم شراء ${t.name} ${t.emoji}', color: err == null ? AppColors.green : AppColors.red);
                  },
                )),
              ],
            ),
          ),
      ],
    );
  }
}
