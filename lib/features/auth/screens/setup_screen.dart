import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon_card.dart';

/// تظهر عندما لا تكون إعدادات Firebase مضبوطة.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CartoonCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⚙️', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 8),
                  Text('إعدادات Firebase ناقصة',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.dark)),
                  SizedBox(height: 8),
                  Text(
                    'ضع مفاتيح مشروعك في lib/core/firebase/firebase_options.dart\n'
                    'أو أضفها كـ Secrets في GitHub (راجع FIREBASE_SETUP.md).',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
