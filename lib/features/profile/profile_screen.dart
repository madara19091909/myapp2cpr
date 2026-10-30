import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/toast.dart';
import '../auth/services/auth_service.dart';
import '../game/state/game_state.dart';
import '../progression/screens/progression_screen.dart';
import '../social/social_screen.dart';

/// صفحة اللاعب الرئيسية، وتحتوي على المكافآت والأصدقاء والمهام.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.firebaseReady = true});

  final bool firebaseReady;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileSection { home, rewards, friends, tasks }

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileSection _section = _ProfileSection.home;

  String get _title {
    switch (_section) {
      case _ProfileSection.home:
        return 'حسابي';
      case _ProfileSection.rewards:
        return 'المكافآت';
      case _ProfileSection.friends:
        return 'الأصدقاء';
      case _ProfileSection.tasks:
        return 'المهام والإنجازات';
    }
  }

  void _open(_ProfileSection section) => setState(() => _section = section);

  Future<void> _editName(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اسم المزارع'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'اكتب اسمك داخل اللعبة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('حفظ')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final cleaned = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return;
    try {
      await context.read<GameState>().setPlayerName(cleaned);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'تعذر تحديث الاسم على الخادم', color: AppColors.red);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final game = context.read<GameState>();
    await game.flushSave();
    if (!context.mounted) return;

    if (game.cloudSyncError != null) {
      final continueLogout = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('الحفظ السحابي لم يكتمل'),
          content: Text(
            '${game.cloudSyncError}\n\nإذا سجلت الخروج الآن، قد لا تنتقل آخر تغييراتك إلى حسابك. هل تريد المتابعة رغم ذلك؟',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تسجيل الخروج على مسؤوليتي'),
            ),
          ],
        ),
      );
      if (!context.mounted || continueLogout != true) return;
    }

    await AuthService().signOut();
    game.reset();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F8F5), Color(0xFFEEF2E9)],
        ),
      ),
      child: Column(
        children: [
          _ProfileSubHeader(
            title: _title,
            showBack: _section != _ProfileSection.home,
            onBack: () => _open(_ProfileSection.home),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (_section) {
                _ProfileSection.home => _ProfileDashboard(
                    key: const ValueKey('profile-home'),
                    onOpen: _open,
                    onEditName: () => _editName(context, game.playerName),
                    onLogout: () => _logout(context),
                  ),
                _ProfileSection.rewards => const _RewardsPage(key: ValueKey('profile-rewards')),
                _ProfileSection.friends => SocialScreen(
                    key: const ValueKey('profile-friends'),
                    firebaseReady: widget.firebaseReady,
                  ),
                _ProfileSection.tasks => const ProgressionScreen(key: ValueKey('profile-tasks')),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSubHeader extends StatelessWidget {
  const _ProfileSubHeader({required this.title, required this.showBack, required this.onBack});

  final String title;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: onBack,
                tooltip: 'رجوع إلى الملف الشخصي',
                style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.dark),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      );
}

class _ProfileDashboard extends StatelessWidget {
  const _ProfileDashboard({
    super.key,
    required this.onOpen,
    required this.onEditName,
    required this.onLogout,
  });

  final ValueChanged<_ProfileSection> onOpen;
  final VoidCallback onEditName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final isOffline = game.uid == null;
    final rewardsEnabled = game.uid != null && !game.legacyUnverified;
    final readyRewards = rewardsEnabled
        ? (game.canClaimDailyReward ? 1 : 0) + (game.canClaimLucky ? 1 : 0)
        : 0;
    final readyMissions = game.legacyUnverified
        ? 0
        : GameState.dailyMissionDefinitions.where(game.canClaimDailyMission).length +
            GameState.achievementDefinitions.where(game.canClaimAchievement).length;

    return ListView(
      key: const PageStorageKey('profile-dashboard-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
      children: [
        _ProfileHero(
          name: game.playerName,
          level: game.level,
          xp: game.xp,
          xpNeeded: game.xpNeeded,
          offline: isOffline,
          legacyUnverified: game.legacyUnverified,
          onEdit: onEditName,
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(child: _ProfileStat(icon: Icons.account_balance_wallet_rounded, value: formatIqd(game.money), label: 'الرصيد', tint: const Color(0xFFE9F6E8))),
            const SizedBox(width: 9),
            Expanded(child: _ProfileStat(icon: Icons.diamond_rounded, value: formatNumber(game.gold), label: 'ذهب', tint: const Color(0xFFFFF3D7))),
            const SizedBox(width: 9),
            Expanded(child: _ProfileStat(icon: Icons.stars_rounded, value: formatNumber(game.xp), label: 'الخبرة', tint: const Color(0xFFE9F0FF))),
          ],
        ),
        const SizedBox(height: 23),
        const Padding(
          padding: EdgeInsetsDirectional.only(start: 3, bottom: 10),
          child: Text('مركز اللاعب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.dark)),
        ),
        _ProfileActionCard(
          icon: Icons.card_giftcard_rounded,
          title: 'المكافآت والهدايا',
          subtitle: 'هدية الدخول اليومي وصندوق الحظ',
          tint: const Color(0xFFFFF0D7),
          iconColor: const Color(0xFFE69B28),
          badge: readyRewards > 0 ? '$readyRewards جديدة' : null,
          onTap: () => onOpen(_ProfileSection.rewards),
        ),
        const SizedBox(height: 9),
        _ProfileActionCard(
          icon: Icons.people_alt_rounded,
          title: 'الأصدقاء',
          subtitle: 'طلبات الصداقة وزيارة المزارع',
          tint: const Color(0xFFE8F1FF),
          iconColor: const Color(0xFF5287CE),
          onTap: () => onOpen(_ProfileSection.friends),
        ),
        const SizedBox(height: 9),
        _ProfileActionCard(
          icon: Icons.flag_rounded,
          title: 'المهام والإنجازات',
          subtitle: 'أكمل أهدافك واجمع جوائز التقدم',
          tint: const Color(0xFFE9F5E7),
          iconColor: const Color(0xFF4A9C50),
          badge: readyMissions > 0 ? '$readyMissions جاهزة' : null,
          onTap: () => onOpen(_ProfileSection.tasks),
        ),
        if (game.legacyUnverified) ...[
          const SizedBox(height: 13),
          const _NoticeCard(
            icon: Icons.verified_user_outlined,
            text: 'حسابك القديم قيد المراجعة الأمنية. بعض العمليات والمكافآت متوقفة مؤقتاً إلى أن تتم مراجعة الحساب.',
          ),
        ],
        if (!isOffline && game.cloudSyncError != null) ...[
          const SizedBox(height: 13),
          _NoticeCard(icon: Icons.cloud_off_rounded, text: game.cloudSyncError!),
        ],
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEditName,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('تعديل الاسم'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  side: const BorderSide(color: Color(0xFFDCE2D7)),
                  backgroundColor: Colors.white.withValues(alpha: .8),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            if (!isOffline) ...[
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('تسجيل الخروج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: Color(0xFFF0D5D2)),
                    backgroundColor: Colors.white.withValues(alpha: .8),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.level,
    required this.xp,
    required this.xpNeeded,
    required this.offline,
    required this.legacyUnverified,
    required this.onEdit,
  });

  final String name;
  final int level;
  final int xp;
  final int xpNeeded;
  final bool offline;
  final bool legacyUnverified;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final needed = xpNeeded <= 0 ? 1 : xpNeeded;
    final ratio = (xp / needed).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF354D42), Color(0xFF233A33)],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: const [BoxShadow(color: Color(0x1F203A2E), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: .35), width: 1.5),
                ),
                child: const Text('🧑‍🌾', style: TextStyle(fontSize: 37)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('مزارع • المستوى $level', style: const TextStyle(color: Color(0xFFD7E4D8), fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 7),
                    Wrap(spacing: 5, children: [
                      _StatusPill(label: offline ? 'محلي' : legacyUnverified ? 'قيد المراجعة' : 'متصل', color: offline ? const Color(0xFFFFD98A) : legacyUnverified ? const Color(0xFFFFD98A) : const Color(0xFFB9E9BE)),
                    ]),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'تعديل الاسم',
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .12), foregroundColor: Colors.white),
                icon: const Icon(Icons.edit_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('التقدم للمستوى التالي', style: TextStyle(color: Color(0xFFE0E9E0), fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$xp / $needed XP', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: .17),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFBCEB85)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.icon, required this.value, required this.label, required this.tint});
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE6EAE2)), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 9, offset: Offset(0, 3))]),
        child: Column(
          children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 19, color: AppColors.dark)),
            const SizedBox(height: 7),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.dark))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(21), border: Border.all(color: const Color(0xFFE5EAE2))),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 24, color: iconColor)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.dark)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ]),
                ),
                if (badge != null) ...[
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEAF5E7), borderRadius: BorderRadius.circular(20)), child: Text(badge!, style: const TextStyle(fontSize: 9, color: Color(0xFF43834A), fontWeight: FontWeight.w900))),
                  const SizedBox(width: 7),
                ],
                const Icon(Icons.chevron_left_rounded, color: Color(0xFF9BA69A), size: 23),
              ],
            ),
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .55))),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
      );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF4DF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF0D7A7))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFF9A6C28), size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF765728), fontSize: 11, height: 1.4, fontWeight: FontWeight.w700))),
        ]),
      );
}

class _RewardsPage extends StatelessWidget {
  const _RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final rewardsEnabled = game.uid != null && !game.legacyUnverified;
    final nextDay = game.canClaimDailyReward ? (game.dailyStreak % 7) + 1 : (game.dailyStreak == 0 ? 1 : game.dailyStreak);
    final cash = 300 + (nextDay - 1) * 50;
    final gold = nextDay == 7 ? 1 : 0;

    return ListView(
      key: const PageStorageKey('profile-rewards-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const Text('هداياك بانتظارك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.dark)),
        const SizedBox(height: 5),
        const Text('تابع سلسلة الدخول وافتح صندوق الحظ اليومي.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4E9B69), Color(0xFF286A4D)]),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [BoxShadow(color: Color(0x1D1F5D3A), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 30), SizedBox(width: 10), Expanded(child: Text('هدية الدخول اليومي', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)))]),
            const SizedBox(height: 8),
            Text('${game.canClaimDailyReward ? 'مكافأة اليوم $nextDay' : 'تم استلام مكافأة اليوم'} من 7  •  +${formatIqd(cash)}  •  +$gold ذهب', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 14),
            Row(children: List.generate(7, (i) => Expanded(child: Container(
              margin: const EdgeInsetsDirectional.only(end: 5),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: i < game.dailyStreak ? const Color(0xFFFFD875) : Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withValues(alpha: .35))),
              child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(color: i < game.dailyStreak ? AppColors.dark : Colors.white, fontWeight: FontWeight.w900)),
            )))),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!game.canClaimDailyReward || !rewardsEnabled) ? null : () async {
                  final error = await context.read<GameState>().claimDailyReward();
                  if (!context.mounted) return;
                  showToast(context, error ?? 'مبروك! تمت إضافة المكافأة إلى رصيدك', color: error == null ? AppColors.green : AppColors.red);
                },
                icon: Icon(game.canClaimDailyReward ? Icons.redeem_rounded : Icons.check_circle_rounded),
                label: Text(!rewardsEnabled ? (game.legacyUnverified ? 'بانتظار مراجعة الحساب' : 'يتطلب اتصالاً') : game.canClaimDailyReward ? 'استلم مكافأتك' : 'تم استلام مكافأة اليوم'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD875), foregroundColor: const Color(0xFF3D4B37), disabledBackgroundColor: Colors.white24, disabledForegroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), border: Border.all(color: const Color(0xFFE5EAE2))),
          child: Row(children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xFFFFF0D9), borderRadius: BorderRadius.circular(17)), child: const Center(child: Text('🎲', style: TextStyle(fontSize: 30)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('صندوق الحظ اليومي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.dark)),
              const SizedBox(height: 3),
              Text(game.canClaimLucky ? 'فرصة جديدة بانتظارك اليوم' : 'استلمته اليوم • سلسلة ${game.luckyStreak}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ])),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: (!game.canClaimLucky || !rewardsEnabled) ? null : () async {
                final result = await context.read<GameState>().claimLuckyChest();
                if (!context.mounted) return;
                final failed = result != null && (result.contains('تعذر') || result.contains('خطأ') || result.contains('مراجعة'));
                showToast(context, result ?? 'تم', color: failed ? AppColors.red : AppColors.green);
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEDAA45), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFE2E5E0), disabledForegroundColor: AppColors.muted, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              child: Text(!rewardsEnabled ? (game.legacyUnverified ? 'موقوف' : 'اتصل') : game.canClaimLucky ? 'افتح' : 'تم'),
            ),
          ]),
        ),
        if (game.legacyUnverified) ...[
          const SizedBox(height: 12),
          const _NoticeCard(icon: Icons.lock_clock_rounded, text: 'المكافآت متوقفة مؤقتاً لحسابك القديم حتى تكتمل مراجعته الأمنية.'),
        ],
      ],
    );
  }
}
