import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../game/state/game_state.dart';
import '../home/home_screen.dart';
import 'screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const _FarmSplash();
        final user = snap.data;
        if (user == null) return const LoginScreen();
        if (user.isAnonymous) {
          // Older app versions may still have an anonymous session persisted.
          // Sign it out so every player must choose login or account creation.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (FirebaseAuth.instance.currentUser?.isAnonymous == true) {
              FirebaseAuth.instance.signOut();
            }
          });
          return const LoginScreen();
        }
        return _GameLoader(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _GameLoader extends StatefulWidget {
  const _GameLoader({super.key, required this.user});

  final User user;

  @override
  State<_GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<_GameLoader> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAccount();
  }

  Future<bool> _loadAccount() => context.read<GameState>().loadForUser(widget.user.uid);

  void _retry() {
    setState(() => _future = _loadAccount());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const _FarmSplash();
        if (snapshot.hasError || snapshot.data != true) {
          final game = context.watch<GameState>();
          return _AccountLoadFailure(
            message: game.loadError ?? 'لم نتأكد من تحميل بيانات حسابك من Firebase.',
            onRetry: _retry,
          );
        }
        return const HomeScreen();
      },
    );
  }
}

class _AccountLoadFailure extends StatelessWidget {
  const _AccountLoadFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌐', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 10),
                      const Text(
                        'تعذر تحميل مزرعتك من السحابة',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'لم نحمّل الحفظ المحلي فوق بيانات حسابك، ولم نكتب بيانات افتراضية إلى Firestore. افحص الإنترنت وصلاحيات قاعدة البيانات ثم أعد المحاولة.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة تحميل البيانات'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text('تسجيل الخروج'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Branded loading screen used while Firebase authentication/account data loads.
class _FarmSplash extends StatelessWidget {
  const _FarmSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.grass.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.outline, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('🌾', style: TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 18),
              const Text(
                'مزرعتي',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'جاري تحميل مزرعتك بأمان...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
