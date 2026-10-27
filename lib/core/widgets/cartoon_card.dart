import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CartoonCard extends StatelessWidget {
  const CartoonCard({super.key, required this.child, this.color = Colors.white, this.padding = const EdgeInsets.all(14), this.margin = const EdgeInsets.only(bottom: 14)});

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }
}
