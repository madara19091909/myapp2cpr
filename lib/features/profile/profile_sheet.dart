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
    context.read<GameState>().setPlayerName(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final user = g.uid == null ? null : FirebaseAuth.instance.currentUser;
    final isOffline = g.uid == null;

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
            Text(isOffline ? 'وضع اللعب المحلي 📱' : (user?.email ?? ''),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54)),
            TextButton.icon(
              onPressed: () => _editName(context, g.playerName),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('تغيير اسم المزارع'),
            ),
            const SizedBox(height: 4),
            Text('⭐ المستوى ${g.level}   •   💵 ${formatIqd(g.money)}   •   🪙 ${g.gold}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            if (isOffline) ...[
              const SizedBox(height: 10),
              const Text('تقدمك محفوظ على هذا الجهاز فقط لأن Firebase غير مهيأ حالياً. أعد إعداد Firebase لتفعيل الحسابات والحفظ السحابي.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            ],
            if (!isOffline) ...[
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
          ],
        ),
      ),
    );
  }
}
