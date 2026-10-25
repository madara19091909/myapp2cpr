import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/cartoon_button.dart';
import '../auth/services/auth_service.dart';
import '../game/state/game_state.dart';

void showProfileSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  Future<void> _logout(BuildContext context) async {
    final game = context.read<GameState>();
    Navigator.of(context).pop();
    await game.flushSave();
    await AuthService().signOut();
    game.reset();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? true;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.soilDark, width: 4)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sky,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [BoxShadow(color: AppColors.soilDark, offset: Offset(0, 4))],
              ),
              child: const Text('🧑‍🌾', style: TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 10),
            Text(g.playerName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.dark)),
            Text(isGuest ? 'حساب ضيف 👻' : (user?.email ?? ''),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(height: 12),
            Text('⭐ المستوى ${g.level}   •   💵 ${formatIqd(g.money)}   •   🪙 ${g.gold}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            if (isGuest) ...[
              const SizedBox(height: 10),
              const Text('⚠️ حساب الضيف يضيع تقدمك عند تسجيل الخروج. أنشئ حساباً دائماً للحفاظ عليه.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CartoonButton(
                color: AppColors.red,
                leading: '🚪',
                label: 'تسجيل الخروج',
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
