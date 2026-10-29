import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../../shop/data/shop_data.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final transactions = game.transactions.where((entry) {
      final text = '${entry['title'] ?? ''} ${entry['detail'] ?? ''}'.toLowerCase();
      final money = (entry['money'] as num?)?.toInt() ?? 0;
      final gold = (entry['gold'] as num?)?.toInt() ?? 0;
      final matchesQuery = text.contains(_query.trim().toLowerCase());
      final matchesFilter = _filter == 'all' || (_filter == 'income' && (money > 0 || gold > 0)) || (_filter == 'expense' && (money < 0 || gold < 0));
      return matchesQuery && matchesFilter;
    }).toList(growable: false);
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
              style: TextStyle(color: AppColors.dark.withValues(alpha: .72), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _DailyRewardCard(game: game),
          const SizedBox(height: 14),
          _DailyMarketBoard(game: game),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Text('📒 سجل المعاملات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            Text('${transactions.length} / ${game.transactions.length}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'ابحث في سجل العمليات...', prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _TransactionFilter(label: 'الكل', value: 'all', selected: _filter, onTap: (v) => setState(() => _filter = v)),
            _TransactionFilter(label: 'الأرباح', value: 'income', selected: _filter, onTap: (v) => setState(() => _filter = v)),
            _TransactionFilter(label: 'المصروفات', value: 'expense', selected: _filter, onTap: (v) => setState(() => _filter = v)),
          ]),
          const SizedBox(height: 8),
          if (game.transactions.isEmpty)
            const CartoonCard(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Column(children: [Text('🧺', style: TextStyle(fontSize: 42)), SizedBox(height: 8), Text('ماكو معاملات لحد الآن', style: TextStyle(fontWeight: FontWeight.w800)), Text('عمليات الشراء والحصاد والمكافآت راح تظهر هنا')]),
            ))
          else if (transactions.isEmpty)
            const CartoonCard(child: Padding(padding: EdgeInsets.all(18), child: Text('ما لقينا معاملات تطابق البحث أو الفلتر.', textAlign: TextAlign.center)))
          else
            ...transactions.map((entry) => _TransactionTile(entry: entry)),
        ],
      ),
    );
  }
}

class _DailyMarketBoard extends StatelessWidget {
  const _DailyMarketBoard({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final crops = ShopData.crops.toList()
      ..sort((a, b) => game.marketSalePrice(b).compareTo(game.marketSalePrice(a)));
    final date = DateTime.now();
    return CartoonCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📊', style: TextStyle(fontSize: 27)),
          SizedBox(width: 8),
          Expanded(child: Text('أسعار سوق اليوم', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark))),
        ]),
        const SizedBox(height: 4),
        Text('الأسعار تتجدد يومياً ضمن نطاق 85%–120% من السعر الأساسي. السعر يشمل مكافأة الحيوانات الأليفة؛ المعول يزيد كمية الحصاد.',
          style: TextStyle(fontSize: 11, color: AppColors.dark.withValues(alpha: .68), height: 1.35)),
        const SizedBox(height: 8),
        Text('تاريخ السوق: ${date.day}/${date.month}/${date.year}',
          style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
        const Divider(height: 18),
        for (final crop in crops.take(6))
          Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            Text(crop.emoji, style: const TextStyle(fontSize: 23)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.dark)),
              Text('السوق ${game.marketPricePercent(crop)}%', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ])),
            Text('${formatIqd(game.marketSalePrice(crop))} / قطعة',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.green)),
          ])),
      ]),
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final nextDay = game.canClaimDailyReward
        ? (game.dailyStreak % 7) + 1
        : (game.dailyStreak == 0 ? 1 : game.dailyStreak);
    final cash = 2000 + (nextDay - 1) * 500;
    final gold = nextDay == 7 ? 2 : 0;
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
          decoration: BoxDecoration(color: i < game.dailyStreak ? AppColors.gold : Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: .65))),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.soil.withValues(alpha: .55)), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 2))]),
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


class _TransactionFilter extends StatelessWidget {
  const _TransactionFilter({required this.label, required this.value, required this.selected, required this.onTap});
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return ChoiceChip(label: Text(label), selected: active, onSelected: (_) => onTap(value));
  }
}
