import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7DD), Color(0xFFFFE6B3)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          const Text('🏪 سوق المزرعة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.dark)),
          const SizedBox(height: 5),
          Text('تابع أرباحك واستلم مكافآتك اليومية',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dark.withOpacity(.72), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _DailyRewardCard(game: game),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Text('📒 سجل المعاملات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            Text('${game.transactions.length} عملية', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          if (game.transactions.isEmpty)
            const CartoonCard(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Column(children: [Text('🧺', style: TextStyle(fontSize: 42)), SizedBox(height: 8), Text('ماكو معاملات لحد الآن', style: TextStyle(fontWeight: FontWeight.w800)), Text('عمليات الشراء والحصاد والمكافآت راح تظهر هنا')]),
            ))
          else
            ...game.transactions.map((entry) => _TransactionTile(entry: entry)),
        ],
      ),
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final nextDay = game.canClaimDailyReward
        ? (game.dailyStreak >= 7 ? 7 : game.dailyStreak + 1)
        : (game.dailyStreak == 0 ? 1 : game.dailyStreak);
    final cash = 15000 + (nextDay - 1) * 5000;
    final gold = nextDay == 7 ? 5 : 1;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF237D3A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1B5E20), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x332E5D25), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Text('🎁', style: TextStyle(fontSize: 34)), SizedBox(width: 10), Expanded(child: Text('هدية الدخول اليومي', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))) ]),
        const SizedBox(height: 8),
        Text('${game.canClaimDailyReward ? 'مكافأة اليوم $nextDay' : 'تم استلام مكافأة اليوم'} من 7  •  +${formatIqd(cash)}  •  +$gold 🪙', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: List.generate(7, (i) => Expanded(child: Container(
          margin: const EdgeInsetsDirectional.only(end: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: i < game.dailyStreak ? AppColors.gold : Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(.65))),
          child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(color: i < game.dailyStreak ? AppColors.dark : Colors.white, fontWeight: FontWeight.w900)),
        )))),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: CartoonButton(
          color: game.canClaimDailyReward ? AppColors.orange : const Color(0xFFBDBDBD),
          leading: game.canClaimDailyReward ? '🎉' : '✅',
          label: game.canClaimDailyReward ? 'استلم مكافأتك' : 'تم استلام مكافأة اليوم',
          onPressed: game.canClaimDailyReward ? () {
            final error = context.read<GameState>().claimDailyReward();
            showToast(context, error ?? 'مبروك! تمت إضافة المكافأة إلى رصيدك', color: error == null ? AppColors.green : AppColors.red);
          } : null,
        )),
      ]),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final money = (entry['money'] as num?)?.toInt() ?? 0;
    final gold = (entry['gold'] as num?)?.toInt() ?? 0;
    final at = DateTime.tryParse(entry['at']?.toString() ?? '');
    final title = entry['title']?.toString() ?? 'معاملة';
    final detail = entry['detail']?.toString() ?? '';
    final positive = money > 0 || gold > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.soil.withOpacity(.55)), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 2))]),
      child: Row(children: [
        Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: positive ? const Color(0xFFE3F5D9) : const Color(0xFFFFE8D2), borderRadius: BorderRadius.circular(13)), child: Text(positive ? '📈' : '🛒', style: const TextStyle(fontSize: 22))),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          Text(detail, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          if (at != null) Text('${at.day}/${at.month}/${at.year} • ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.black45, fontSize: 11)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (money != 0) Text('${money > 0 ? '+' : ''}${formatIqd(money)}', style: TextStyle(fontWeight: FontWeight.w900, color: money > 0 ? AppColors.green : AppColors.red, fontSize: 12)),
          if (gold != 0) Text('${gold > 0 ? '+' : ''}$gold 🪙', style: TextStyle(fontWeight: FontWeight.w900, color: gold > 0 ? AppColors.orange : AppColors.red, fontSize: 12)),
        ]),
      ]),
    );
  }
}
