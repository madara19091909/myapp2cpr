import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../game/state/game_state.dart';

/// Compact farm-only status header. It is deliberately not shown on the other tabs.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.onProfileTap});
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF245B3E), Color(0xFF347A50), Color(0xFF438B5D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x24234D35), blurRadius: 16, offset: Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Stack(
          children: [
            Positioned(
              top: -72,
              left: -32,
              child: _GlowCircle(size: 150, opacity: .055),
            ),
            Positioned(
              bottom: -84,
              right: -40,
              child: _GlowCircle(size: 150, opacity: .045),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 7, 14, 11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _Avatar(level: game.level, onTap: onProfileTap),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'مزرعتي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'مزرعتك تكبر كل يوم 🌱',
                                style: TextStyle(
                                  color: Color(0xDDE8F4EA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CloudSyncStatus(
                          saving: game.isCloudSaving,
                          error: game.cloudSyncError,
                          lastSync: game.lastCloudSync,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: _BalanceCard(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'الرصيد',
                            value: formatIqd(game.money),
                            accent: const Color(0xFFFFD782),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BalanceCard(
                            icon: Icons.stars_rounded,
                            label: 'الذهب',
                            value: formatNumber(game.gold),
                            accent: const Color(0xFFFFD66B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

class _CloudSyncStatus extends StatelessWidget {
  const _CloudSyncStatus({required this.saving, required this.error, required this.lastSync});
  final bool saving;
  final String? error;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final color = saving
        ? const Color(0xFFFFD782)
        : error != null
            ? const Color(0xFFFFC5BD)
            : lastSync != null
                ? const Color(0xFFBDF3CE)
                : Colors.white70;
    final icon = saving
        ? Icons.cloud_sync_rounded
        : error != null
            ? Icons.cloud_off_rounded
            : lastSync != null
                ? Icons.cloud_done_rounded
                : Icons.cloud_queue_rounded;
    final label = saving ? 'يحفظ' : error != null ? 'غير متزامن' : lastSync != null ? 'محفوظ' : 'ينتظر';
    return Tooltip(
      message: error ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .13)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
          ],
        ),
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
        button: true,
        label: 'الملف الشخصي، المستوى $level',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .58), width: 1.3),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('🧑‍🌾', style: TextStyle(fontSize: 23)),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFF2D6040), width: 1.2),
                    ),
                    child: Text(
                      '$level',
                      style: const TextStyle(color: Color(0xFF254C35), fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
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
        constraints: const BoxConstraints(minHeight: 49),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .15)),
        ),
        child: Row(
          children: [
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(color: accent.withValues(alpha: .18), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .73), fontSize: 9, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('المستوى $level', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('$xp / $safeNeeded XP', style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 5,
            color: Colors.white.withValues(alpha: .18),
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFFD166), Color(0xFFFFF0A8)]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
