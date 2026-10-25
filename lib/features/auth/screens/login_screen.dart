import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/toast.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AuthFailure catch (e) {
      if (mounted) showToast(context, e.message, color: AppColors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (_register && _name.text.trim().isEmpty) {
      showToast(context, 'اكتب اسم المزارع', color: AppColors.red);
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      showToast(context, 'اكتب بريداً إلكترونياً صحيحاً', color: AppColors.red);
      return;
    }
    if (pass.length < 6) {
      showToast(context, 'كلمة المرور 6 أحرف على الأقل', color: AppColors.red);
      return;
    }
    _run(() => _register ? _auth.register(_name.text, email, pass) : _auth.signIn(email, pass));
  }

  void _forgot() {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showToast(context, 'اكتب بريدك أولاً ثم اضغط نسيت كلمة المرور', color: AppColors.red);
      return;
    }
    _run(() async {
      await _auth.resetPassword(email);
      if (mounted) showToast(context, 'تم إرسال رابط إعادة التعيين لبريدك 📧', color: AppColors.green);
    });
  }

  InputDecoration _decoration(String hint, String emoji) => InputDecoration(
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.soilDark, width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.green, width: 3),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sky, Color(0xFFBFEFFF), AppColors.grass],
            stops: [0, .35, .36],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const Text('🚜', style: TextStyle(fontSize: 64)),
                    const Text(
                      'مزرعة الأبطال',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CartoonCard(
                      child: Column(
                        children: [
                          Text(
                            _register ? 'حساب جديد ✨' : 'أهلاً بعودتك 👋',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.dark),
                          ),
                          const SizedBox(height: 12),
                          if (_register) ...[
                            TextField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration('اسم المزارع', '🧑‍🌾'),
                            ),
                            const SizedBox(height: 10),
                          ],
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: _decoration('البريد الإلكتروني', '📧'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _pass,
                            obscureText: _hide,
                            textDirection: TextDirection.ltr,
                            onSubmitted: (_) => _submit(),
                            decoration: _decoration('كلمة المرور', '🔑').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _hide = !_hide),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: CartoonButton(
                              color: AppColors.green,
                              leading: _busy ? '⏳' : (_register ? '🌱' : '🚪'),
                              label: _busy ? 'جارٍ التنفيذ...' : (_register ? 'إنشاء الحساب' : 'تسجيل الدخول'),
                              onPressed: _busy ? null : _submit,
                            ),
                          ),
                          if (!_register)
                            TextButton(
                              onPressed: _busy ? null : _forgot,
                              child: const Text('نسيت كلمة المرور؟',
                                  style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          TextButton(
                            onPressed: _busy ? null : () => setState(() => _register = !_register),
                            child: Text(
                              _register ? 'عندي حساب؟ سجّل الدخول' : 'ما عندك حساب؟ أنشئ واحداً',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: CartoonButton(
                        color: AppColors.purple,
                        leading: '👻',
                        label: 'الدخول كضيف',
                        onPressed: _busy ? null : () => _run(_auth.signInAsGuest),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
