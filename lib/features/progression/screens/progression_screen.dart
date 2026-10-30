import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';

/// شاشة المهام اليومية والإنجازات الدائمة.
class ProgressionScreen extends StatelessWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final dailyClaimable = game.legacyUnverified ? 0 : GameState.dailyMissionDefinitions.where(game.canClaimDailyMission).length;
    final achievementClaimable = game.legacyUnverified ? 0 : GameState.achievementDefinitions.where(game.canClaimAchievement).length;
    final claimedAchievements = GameState.achievementDefinitions.where((a) => game.isAchievementClaimed(a['id'] as String)).length;
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF7DD), Color(0xFFFFE6B3)],
      )),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 28),
        children: [
          const Text('🏆 المهام والإنجازات', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.dark)),
          const SizedBox(height: 5),
          const Text('أنجز أهدافك، اجمع المكافآت، وطوّر مزرعتك خطوة بخطوة', textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(child: _Summary(emoji: '🎯', title: 'جاهزة للاستلام', value: '${dailyClaimable + achievementClaimable}')),
            const SizedBox(width: 8),
            Expanded(child: _Summary(emoji: '🏅', title: 'إنجازات مستلمة', value: '$claimedAchievements/${GameState.achievementDefinitions.length}')),
          ]),
          const SizedBox(height: 12),
          if (game.legacyUnverified) ...[
            const CartoonCard(
              color: Color(0xFFFFF3CD),
              child: const Text(
                'حسابك من إصدار سابق. تم الحفاظ على تقدمك، لكن مكافآت المهام والإنجازات متوقفة مؤقتاً إلى أن تتم مراجعة رصيد الحساب من الإدارة.',
                style: TextStyle(color: Color(0xFF765400), fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
          ],
          CartoonCard(
            color: const Color(0xFFE8F5E9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${game.weeklyEvent.emoji} حدث الأسبوع: ${game.weeklyEvent.title}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(game.weeklyEvent.description, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'بيع +${game.weeklyEvent.sellBonusPercent}%  •  خبرة +${game.weeklyEvent.xpBonusPercent}%  •  نمو ×${game.weeklyEvent.growMultiplier}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CartoonCard(
            color: const Color(0xFFFFF8E1),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('صندوق الحظ اليومي', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(
                        game.canClaimLucky ? 'متاح الآن — افتحه!' : 'استلمته اليوم • سلسلة ${game.luckyStreak}',
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: game.canClaimLucky ? AppColors.orange : Colors.grey),
                  onPressed: !game.canClaimLucky
                      ? null
                      : () async {
                          final msg = await context.read<GameState>().claimLuckyChest();
                          if (!context.mounted) return;
                          showToast(
                            context,
                            msg ?? 'تم',
                            color: (msg != null && !msg.contains('بالفعل')) ? AppColors.green : AppColors.red,
                          );
                        },
                  child: const Text('فتح', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: '📅 مهام اليوم', subtitle: 'تتجدد المهام عند بداية يوم جديد'),
          for (final mission in GameState.dailyMissionDefinitions)
            _MissionCard(
              icon: mission['icon'] as String,
              title: mission['title'] as String,
              description: mission['description'] as String,
              progress: game.dailyMissionProgress(mission),
              target: mission['target'] as int,
              reward: '${formatNumber(mission['money'] as int)} د.ع + ${mission['xp']} خبرة',
              claimed: game.isDailyMissionClaimed(mission['id'] as String),
              canClaim: !game.legacyUnverified && game.canClaimDailyMission(mission),
              onClaim: () => _claim(context, () => context.read<GameState>().claimDailyMission(mission['id'] as String)),
            ),
          const SizedBox(height: 14),
          const _SectionTitle(title: '🌟 الإنجازات الدائمة', subtitle: 'كل إنجاز يُكافأ مرة واحدة فقط'),
          for (final achievement in GameState.achievementDefinitions)
            _MissionCard(
              icon: achievement['icon'] as String,
              title: achievement['title'] as String,
              description: achievement['description'] as String,
              progress: game.achievementProgress(achievement),
              target: achievement['target'] as int,
              reward: '${formatNumber(achievement['money'] as int)} د.ع + ${achievement['gold']} ذهب',
              claimed: game.isAchievementClaimed(achievement['id'] as String),
              canClaim: !game.legacyUnverified && game.canClaimAchievement(achievement),
              onClaim: () => _claim(context, () => context.read<GameState>().claimAchievement(achievement['id'] as String)),
            ),
        ],
      ),
    );
  }

  Future<void> _claim(BuildContext context, Future<String?> Function() action) async {
    final error = await action();
    if (!context.mounted) return;
    showToast(context, error ?? 'مبروك! استلمت مكافأتك 🎉', color: error == null ? AppColors.green : AppColors.red);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.emoji, required this.title, required this.value});
  final String emoji;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => CartoonCard(padding: const EdgeInsets.all(11), child: Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 25)),
    const SizedBox(height: 3),
    Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark)),
    Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
  ]));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(3, 3, 3, 9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark)),
    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
  ]));
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.icon, required this.title, required this.description, required this.progress, required this.target, required this.reward, required this.claimed, required this.canClaim, required this.onClaim});
  final String icon;
  final String title;
  final String description;
  final int progress;
  final int target;
  final String reward;
  final bool claimed;
  final bool canClaim;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final ratio = (progress / target).clamp(0.0, 1.0).toDouble();
    return CartoonCard(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFFFE7A8), borderRadius: BorderRadius.circular(14)), child: Text(icon, style: const TextStyle(fontSize: 26))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.dark)),
        const SizedBox(height: 2),
        Text(description, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 7),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: const Color(0xFFE8D9B9), color: const Color(0xFF55A83B))),
        const SizedBox(height: 4),
        Text('$progress / $target  •  المكافأة: $reward', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
      ])),
      const SizedBox(width: 5),
      SizedBox(width: 74, child: FilledButton(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8), backgroundColor: claimed ? Colors.grey : const Color(0xFF388E3C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
        onPressed: canClaim ? onClaim : null,
        child: Text(claimed ? 'مستلمة' : canClaim ? 'استلام' : 'لاحقاً', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
      )),
    ]));
  }
}
