import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../game/state/game_state.dart';
import '../../profile/profile_sheet.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA9703A), AppColors.wood],
        ),
        border: Border(bottom: BorderSide(color: AppColors.soilDark, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
          child: Row(
            children: [
              _Avatar(level: game.level, onTap: () => showProfileSheet(context)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 5, child: _StatChip(emoji: '💵', text: formatIqd(game.money))),
                        const SizedBox(width: 6),
                        Expanded(flex: 2, child: _StatChip(emoji: '🪙', text: formatNumber(game.gold))),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _XpBar(level: game.level, xp: game.xp, needed: game.xpNeeded),
                    if (game.uid != null) ...[
                      const SizedBox(height: 3),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _CloudSyncStatus(
                          saving: game.isCloudSaving,
                          error: game.cloudSyncError,
                          lastSync: game.lastCloudSync,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
    final Color color;
    final IconData icon;
    final String label;
    if (saving) {
      color = AppColors.gold;
      icon = Icons.cloud_sync_rounded;
      label = 'جارٍ الحفظ';
    } else if (error != null) {
      color = const Color(0xFFFFC2B8);
      icon = Icons.cloud_off_rounded;
      label = 'تعذرت المزامنة';
    } else if (lastSync != null) {
      color = const Color(0xFFB9F6CA);
      icon = Icons.cloud_done_rounded;
      label = 'محفوظ بالسحابة';
    } else {
      color = Colors.white70;
      icon = Icons.cloud_queue_rounded;
      label = 'بانتظار الحفظ';
    }
    final syncTime = lastSync == null
        ? ''
        : '${lastSync!.hour.toString().padLeft(2, "0")}:${lastSync!.minute.toString().padLeft(2, "0")}';
    return Tooltip(
      message: error ?? (lastSync == null ? label : '$label • $syncTime'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'الملف الشخصي، المستوى $level',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 51,
                height: 51,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sky,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: AppColors.soilDark, offset: Offset(0, 3))],
                ),
                child: const Text('🧑‍🌾', style: TextStyle(fontSize: 27)),
              ),
              Positioned(
                bottom: -1,
                left: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$level',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                shadows: AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Semantics(
      label: 'مستوى $level، الخبرة $xp من $safeNeeded',
      child: Row(
        children: [
          Text(
            '⭐ $level',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, shadows: AppTheme.outline),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: progress,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.grass, Color(0xFFB8F55B)]),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$xp / $safeNeeded',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, shadows: AppTheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
