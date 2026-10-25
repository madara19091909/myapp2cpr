import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/screens/setup_screen.dart';

class FarmApp extends StatelessWidget {
  const FarmApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مزرعة الأبطال',
      theme: AppTheme.theme,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: firebaseReady ? const AuthGate() : const SetupScreen(),
    );
  }
}
