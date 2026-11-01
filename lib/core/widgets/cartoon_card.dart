import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// بطاقة كرتونية بظل ثلاثي الأبعاد وحدود واضحة.
class CartoonCard extends StatelessWidget {
  const CartoonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = AppColors.surface,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.outline;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x28000000), offset: Offset(0, 5), blurRadius: 0),
          BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: content,
      ),
    );
  }
}
