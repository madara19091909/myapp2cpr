import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/toast.dart';
import '../game/state/game_state.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final _bankAmount = TextEditingController();
  final _receiver = TextEditingController();
  final _transferAmount = TextEditingController();
  bool _bankBusy = false;
  bool _transferBusy = false;

  @override
  void dispose() {
    _bankAmount.dispose();
    _receiver.dispose();
    _transferAmount.dispose();
    super.dispose();
  }

  BigInt? _readAmount(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty || !RegExp(r'^\d+$').hasMatch(cleaned)) return null;
    return BigInt.tryParse(cleaned);
  }

  Future<void> _moveMoney({required bool deposit}) async {
    final amount = _readAmount(_bankAmount.text);
    if (amount == null || amount <= BigInt.zero) {
      showToast(context, 'اكتب مبلغاً صحيحاً أولاً', color: AppColors.red);
      return;
    }
    context.read<AudioManager>().playClick();
    setState(() => _bankBusy = true);
    final error = await context.read<GameState>().moveMoneyToBank(amount, deposit: deposit);
    if (!mounted) return;
    setState(() => _bankBusy = false);
    if (error == null) {
      _bankAmount.clear();
      showToast(context, deposit ? 'تم إيداع المبلغ في البنك بنجاح' : 'تم سحب المبلغ إلى رصيدك بنجاح', color: AppColors.green);
    } else {
      showToast(context, error, color: AppColors.red);
    }
  }

  Future<String?> _resolvePlayer(String input) async {
    final query = input.trim();
    if (query.isEmpty) return null;
    final db = FirebaseFirestore.instance;
    final byUid = await db.collection('publicProfiles').doc(query).get();
    if (byUid.exists) return byUid.id;
    final matches = await db.collection('publicProfiles').where('name', isEqualTo: query).limit(2).get();
    if (matches.docs.isEmpty) {
      throw StateError('لم يتم العثور على لاعب بهذا الاسم أو المعرّف.');
    }
    if (matches.docs.length > 1) {
      throw StateError('يوجد أكثر من لاعب بهذا الاسم. استخدم UID للاعب المطلوب.');
    }
    return matches.docs.single.id;
  }

  Future<void> _transfer() async {
    final amount = _readAmount(_transferAmount.text);
    if (amount == null || amount <= BigInt.zero) {
      showToast(context, 'اكتب مبلغ التحويل بشكل صحيح', color: AppColors.red);
      return;
    }
    if (context.read<GameState>().uid == null) {
      showToast(context, 'سجّل الدخول أولاً حتى تتمكن من التحويل', color: AppColors.red);
      return;
    }

    setState(() => _transferBusy = true);
    try {
      final receiverUid = await _resolvePlayer(_receiver.text);
      if (!mounted || receiverUid == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('تأكيد التحويل'),
          content: Text('هل تريد تحويل ${formatIqd(amount)} إلى اللاعب المحدد؟ لا يمكن إلغاء التحويل بعد اعتماده.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تأكيد التحويل')),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      context.read<AudioManager>().playClick();
      final error = await context.read<GameState>().transferMoney(receiverUid, amount);
      if (!mounted) return;
      if (error == null) {
        _receiver.clear();
        _transferAmount.clear();
        showToast(context, 'تم تحويل ${formatIqd(amount)} بنجاح', color: AppColors.green);
      } else {
        showToast(context, error, color: AppColors.red);
      }
    } on StateError catch (error) {
      if (mounted) showToast(context, error.message.toString(), color: AppColors.red);
    } catch (_) {
      if (mounted) showToast(context, 'تعذر البحث عن اللاعب. تحقق من الاتصال وحاول مرة ثانية.', color: AppColors.red);
    } finally {
      if (mounted) setState(() => _transferBusy = false);
    }
  }

  Future<void> _selectMusic() async {
    context.read<AudioManager>().playClick();
    final message = await context.read<AudioManager>().pickMusic();
    if (!mounted) return;
    showToast(
      context,
      message ?? 'تم اختيار الأغنية. ستعمل بتكرار مستمر وبمستوى صوت 25%.',
      color: message == null ? AppColors.green : AppColors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final audio = context.watch<AudioManager>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFEAF3F1), Color(0xFFF4F5F8), Color(0xFFE8EEF7)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('البنك', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF172B3A))),
              const SizedBox(height: 4),
              const Text('إدارة أموالك وتحويلها بأمان', style: TextStyle(fontSize: 12, color: Color(0xFF71818C), fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _BankHero(cash: game.money, bank: game.bankMoney),
              const SizedBox(height: 15),
              _GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeading(icon: Icons.swap_vert_rounded, title: 'إيداع وسحب', subtitle: 'قسّم رصيدك بين المحفظة والبنك'),
                    const SizedBox(height: 13),
                    _AmountField(controller: _bankAmount, label: 'المبلغ', hint: 'مثال: 750000'),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'إيداع بالبنك', icon: Icons.south_west_rounded,
                            color: const Color(0xFF177E69), busy: _bankBusy,
                            onTap: _bankBusy || game.uid == null ? null : () => _moveMoney(deposit: true),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _ActionButton(
                            label: 'سحب للمحفظة', icon: Icons.north_east_rounded,
                            color: const Color(0xFF4776B9), busy: _bankBusy,
                            onTap: _bankBusy || game.uid == null ? null : () => _moveMoney(deposit: false),
                          ),
                        ),
                      ],
                    ),
                    if (game.uid == null) ...[
                      const SizedBox(height: 10),
                      const _InlineNotice(text: 'عمليات البنك تحتاج إلى حساب مسجل ومتصل بخدمات Firebase.'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 13),
              _GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeading(icon: Icons.send_rounded, title: 'تحويل الأموال', subtitle: 'حوّل من محفظتك إلى لاعب آخر'),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _receiver,
                      textDirection: TextDirection.rtl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'اسم اللاعب أو UID',
                        hintText: 'اكتب الاسم كما يظهر في اللعبة أو UID',
                        prefixIcon: Icon(Icons.person_search_rounded),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AmountField(controller: _transferAmount, label: 'مبلغ التحويل', hint: 'مثال: 25000'),
                    const SizedBox(height: 11),
                    _ActionButton(
                      label: 'مراجعة وإرسال التحويل', icon: Icons.verified_user_rounded,
                      color: const Color(0xFF7559B8), busy: _transferBusy,
                      onTap: _transferBusy ? null : _transfer,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'يُنفّذ التحويل على الخادم كعملية واحدة: يُخصم من حسابك ويُضاف إلى حساب المستلم، أو تُرفض العملية بالكامل.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, height: 1.5, color: Color(0xFF77838E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              _GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeading(icon: Icons.music_note_rounded, title: 'موسيقى المزرعة', subtitle: 'اختر أغنيتك من الهاتف ودعها تتكرر تلقائياً'),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECE8FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(audio.isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded, color: const Color(0xFF7559B8), size: 25),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(audio.musicName ?? 'لم يتم اختيار أغنية', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF263746))),
                              const SizedBox(height: 3),
                              const Text('الصوت 25%  •  تكرار مستمر', style: TextStyle(fontSize: 10, color: Color(0xFF77838E))),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: audio.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                          onPressed: () { audio.playClick(); audio.toggleMusic(); },
                          icon: Icon(audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectMusic,
                            icon: const Icon(Icons.library_music_rounded),
                            label: const Text('اختيار أغنية'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5F4A9C),
                              side: const BorderSide(color: Color(0xFFD8D0F1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (audio.hasMusic) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'إزالة الأغنية المحفوظة',
                            onPressed: () async {
                              audio.playClick();
                              await audio.clearMusic();
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                          ),
                        ],
                      ],
                    ),
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

class _BankHero extends StatelessWidget {
  const _BankHero({required this.cash, required this.bank});
  final BigInt cash;
  final BigInt bank;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF16384A), Color(0xFF226B68), Color(0xFF398A75)],
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: const [BoxShadow(color: Color(0x26315F68), blurRadius: 23, offset: Offset(0, 11))],
        ),
        child: Stack(
          children: [
            Positioned(left: -32, top: -38, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)))),
            Positioned(right: 120, bottom: -65, child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .045)))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: Color(0xFFD8F3E8), size: 20),
                    const SizedBox(width: 8),
                    const Text('محفظة مزرعتي', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
                      child: const Text('IQD  •  آمن', style: TextStyle(color: Color(0xFFD8F3E8), fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                const Text('الرصيد المتاح للّعب', style: TextStyle(color: Color(0xFFC8E2DA), fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(formatIqd(cash), style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: .2)),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white.withValues(alpha: .2))),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_rounded, color: Color(0xFFFFD98B), size: 21),
                          const SizedBox(width: 9),
                          const Expanded(child: Text('المبلغ المحفوظ بالبنك', style: TextStyle(color: Color(0xFFE2F1EC), fontSize: 11, fontWeight: FontWeight.w700))),
                          Flexible(child: Text(formatIqd(bank), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .76),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .92), width: 1.2),
              boxShadow: const [BoxShadow(color: Color(0x0D263E54), blurRadius: 18, offset: Offset(0, 7))],
            ),
            child: child,
          ),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 39, height: 39, decoration: BoxDecoration(color: const Color(0xFFE8F0EC), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF26705D), size: 21)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF253746))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF82909A))),
          ])),
        ],
      );
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.label, required this.hint});
  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: 'د.ع',
          prefixIcon: const Icon(Icons.payments_outlined),
          isDense: true,
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.color, required this.busy, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 47,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color.withValues(alpha: .55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
        ),
      );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFFF2D8), borderRadius: BorderRadius.circular(13)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF80602C), fontWeight: FontWeight.w700)),
      );
}
