import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../data/shop_data.dart';
import '../widgets/emoji_badge.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ScreenTitle('🛠️ متجر الأدوات'),
        for (final t in ShopData.tools)
          CartoonCard(
            child: Column(
              children: [
                Row(
                  children: [
                    EmojiBadge(t.emoji),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark)),
                          const SizedBox(height: 2),
                          Text(t.description,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          InfoChip('${t.goldPrice} 🪙', color: AppColors.gold),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CartoonButton(
                    color: g.hasTool(t.id) ? AppColors.purple : AppColors.orange,
                    leading: g.hasTool(t.id) ? '✅' : '🪙',
                    label: g.hasTool(t.id) ? 'مملوكة' : 'شراء  •  ${t.goldPrice} عملة',
                    onPressed: g.hasTool(t.id)
                        ? null
                        : () {
                            final err = context.read<GameState>().buyTool(t);
                            showToast(context, err ?? 'تم شراء ${t.name} ${t.emoji}',
                                color: err == null ? AppColors.green : AppColors.red);
                          },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
