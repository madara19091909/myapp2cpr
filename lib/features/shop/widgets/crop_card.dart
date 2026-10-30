import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../models/crop.dart';
import 'emoji_badge.dart';

class CropCard extends StatefulWidget {
  const CropCard({super.key, required this.crop});

  final Crop crop;

  @override
  State<CropCard> createState() => _CropCardState();
}

class _CropCardState extends State<CropCard> {
  int qty = 1;

  void _set(int v) => setState(() => qty = v.clamp(1, 9999).toInt());

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final crop = widget.crop;
    final locked = g.level < crop.requiredLevel;
    final total = crop.price * qty;
    final maxAffordable = (g.money ~/ crop.price).clamp(0, 9999).toInt();
    final canBuy = !locked && total <= g.money;
    final canSell = qty <= g.ownedSeeds(crop.id) && g.ownedSeeds(crop.id) > 0;
    final sellTotal = (crop.price * 0.6).floor() * qty;

    return Opacity(
      opacity: locked ? .6 : 1,
      child: CartoonCard(
        child: Column(
          children: [
            Row(
              children: [
                EmojiBadge(crop.emoji),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop.name,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark)),
                      const SizedBox(height: 2),
                      Text('السعر: ${formatIqd(crop.price)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('السعر الأساسي للبيع: ${formatIqd(crop.sellPrice)} • ⏱ ${formatDuration(crop.growSeconds)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, children: [
                        InfoChip('المستوى ${crop.requiredLevel}',
                            color: locked ? AppColors.red : AppColors.green),
                        InfoChip('لديك ${g.ownedSeeds(crop.id)}', color: AppColors.purple),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundBtn('−', () => _set(qty - 1)),
                Container(
                  width: 64,
                  alignment: Alignment.center,
                  child: Text(formatNumber(qty),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                _RoundBtn('+', () => _set(qty + 1)),
                const SizedBox(width: 8),
                _RoundBtn('+10', () => _set(qty + 10), wide: true),
                const SizedBox(width: 8),
                _RoundBtn('الأقصى', () => _set(maxAffordable < 1 ? 1 : maxAffordable), wide: true),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CartoonButton(
                color: locked || !canBuy ? AppColors.red : AppColors.green,
                leading: locked ? '🔒' : '🛒',
                label: locked
                    ? 'يفتح عند المستوى ${crop.requiredLevel}'
                    : canBuy
                        ? 'شراء  •  ${formatIqd(total)}'
                        : 'الرصيد غير كافٍ • ${formatIqd(total)}',
                onPressed: locked
                    ? null
                    : () async {
                        final err = await context.read<GameState>().buySeed(crop, qty);
                        if (!context.mounted) return;
                        showToast(
                          context,
                          err ?? 'تم شراء ${formatNumber(qty)} × ${crop.name} ${crop.emoji}',
                          color: err == null ? AppColors.green : AppColors.red,
                        );
                      },
              ),
            ),
            if (g.ownedSeeds(crop.id) > 0) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: CartoonButton(
                  color: AppColors.orange,
                  leading: '💰',
                  label: canSell
                      ? 'بيع $qty • استرداد ${formatIqd(sellTotal)}'
                      : 'حدد كمية لا تتجاوز ${formatNumber(g.ownedSeeds(crop.id))}',
                  onPressed: canSell
                      ? () async {
                          final err = await context.read<GameState>().sellSeed(crop, qty);
                          if (!context.mounted) return;
                          showToast(
                            context,
                            err ?? 'تم بيع ${formatNumber(qty)} من بذور ${crop.name} واسترداد ${formatIqd(sellTotal)}',
                            color: err == null ? AppColors.green : AppColors.red,
                          );
                        }
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn(this.text, this.onTap, {this.wide = false});

  final String text;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.symmetric(horizontal: wide ? 10 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(wide ? 14 : 20),
          border: Border.all(color: darken(AppColors.blue, .25), width: 3),
          boxShadow: [BoxShadow(color: darken(AppColors.blue, .25), offset: const Offset(0, 3))],
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, shadows: AppTheme.outline)),
      ),
    );
  }
}
