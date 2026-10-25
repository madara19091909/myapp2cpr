import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CartoonCard extends StatelessWidget {
  const CartoonCard({super.key, required this.child, this.color = Colors.white});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.soilDark, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.soilDark, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }
}
