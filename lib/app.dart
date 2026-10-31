import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/firebase/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

class FarmApp extends StatefulWidget {
  const FarmApp({super.key});

  @override
  State<FarmApp> createState() => _FarmAppState();
}

class _FarmAppState extends State<FarmApp> {
  bool _initializing = true;
  bool _firebaseReady = false;
  String? _firebaseError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeFirebase();
    });
  }

  Future<void> _initializeFirebase() async {
    if (mounted && !_initializing) {
      setState(() {
        _initializing = true;
        _firebaseError = null;
      });
    }

    try {
      if (!DefaultFirebaseOptions.isConfigured) {
        throw StateError('إعدادات Firebase غير مكتملة في firebase_options.dart');
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
      } else {
        Firebase.app();
      }

      // App Check is an additional protection layer. Do not prevent the entire
      // game from opening if its native provider fails to initialize on a device.
      // If Firebase Console enforces App Check, protected requests may still be
      // rejected until the provider / Play Integrity configuration is corrected.
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
        );
      } catch (appCheckError, stackTrace) {
        debugPrint('Firebase App Check activation failed: $appCheckError');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted) return;
      setState(() {
        _firebaseReady = true;
        _initializing = false;
        _firebaseError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _firebaseReady = false;
        _initializing = false;
        _firebaseError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مزرعتي',
      theme: AppTheme.theme,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: _initializing
          ? const _FirebaseBootScreen()
          : _firebaseReady
              ? const AuthGate()
              : _FirebaseFailureScreen(message: _firebaseError ?? 'سبب غير معروف', onRetry: _initializeFirebase),
    );
  }
}

class _FirebaseBootScreen extends StatelessWidget {
  const _FirebaseBootScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.sky, AppColors.grass],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🚜', style: TextStyle(fontSize: 72)),
                SizedBox(height: 16),
                Text('جارٍ الاتصال بخدمات مزرعتي',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 16),
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
}

class _FirebaseFailureScreen extends StatelessWidget {
  const _FirebaseFailureScreen({required this.message, required this.onRetry});

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
                      const Text('☁️', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 10),
                      const Text(
                        'تعذر تشغيل Firebase',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.dark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'لم نفتح نسخة محلية بديلة حتى لا تظهر اللعبة وكأن بيانات حسابك متزامنة وهي ليست كذلك.',
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
                        child: SelectableText(
                          message,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 12, color: AppColors.dark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
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
