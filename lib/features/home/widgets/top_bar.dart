import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../game/state/game_state.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.onProfileTap});
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF244D38), Color(0xFF34734C), Color(0xFF4C8B5C)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x26304E39), blurRadius: 22, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              top: -46, right: -28,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .055)),
              ),
            ),
            Positioned(
              top: 28, left: -48,
              child: Container(
                width: 118, height: 118,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .045)),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _Avatar(level: game.level, onTap: onProfileTap),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مزرعتي', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                              const SizedBox(height: 2),
                              Text('خلّي مزرعتك تكبر كل يوم 🌱', style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        _CloudSyncStatus(saving: game.isCloudSaving, error: game.cloudSyncError, lastSync: game.lastCloudSync),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _BalanceCard(icon: Icons.account_balance_wallet_rounded, label: 'الرصيد', value: formatIqd(game.money), accent: const Color(0xFFFFD782))),
                        const SizedBox(width: 10),
                        Expanded(child: _BalanceCard(icon: Icons.stars_rounded, label: 'الذهب', value: formatNumber(game.gold), accent: const Color(0xFFFFD66B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _XpBar(level: game.level, xp: game.xp, needed: game.xpNeeded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudSyncStatus extends StatelessWidget {
  const _CloudSyncStatus({required this.saving, required this.error, required this.lastSync});
  final bool saving;
  final String? error;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final color = saving ? const Color(0xFFFFD782) : error != null ? const Color(0xFFFFC5BD) : lastSync != null ? const Color(0xFFBDF3CE) : Colors.white70;
    final icon = saving ? Icons.cloud_sync_rounded : error != null ? Icons.cloud_off_rounded : lastSync != null ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded;
    final label = saving ? 'يحفظ' : error != null ? 'غير متزامن' : lastSync != null ? 'محفوظ' : 'ينتظر';
    return Tooltip(
      message: error ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .14))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.level, required this.onTap});
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true, label: 'الملف الشخصي، المستوى $level',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .65), width: 1.5),
        ),
        child: Stack(alignment: Alignment.center, children: [
          const Text('🧑‍🌾', style: TextStyle(fontSize: 27)),
          Positioned(
            right: -2, bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFFD166), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2D6040), width: 1.5)),
              child: Text('$level', style: const TextStyle(color: Color(0xFF254C35), fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.icon, required this.label, required this.value, required this.accent});
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .17)),
    ),
    child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: accent.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: accent, size: 19)),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900))),
      ])),
    ]),
  );
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.level, required this.xp, required this.needed});
  final int level;
  final int xp;
  final int needed;

  @override
  Widget build(BuildContext context) {
    final safeNeeded = needed <= 0 ? 1 : needed;
    final progress = (xp / safeNeeded).clamp(0.0, 1.0).toDouble();
    return Column(children: [
      Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD782), size: 15),
        const SizedBox(width: 5),
        Text('المستوى $level', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text('$xp / $safeNeeded XP', style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 7, color: Colors.white.withValues(alpha: .19),
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(widthFactor: progress, child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD166), Color(0xFFFFF0A8)])))),
        ),
      ),
    ]);
  }
}
