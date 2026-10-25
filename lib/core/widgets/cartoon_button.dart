import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Color darken(Color c, [double amount = .18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color lighten(Color c, [double amount = .12]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// زر كرتوني ثلاثي الأبعاد مع حركة ضغط.
class CartoonButton extends StatefulWidget {
  const CartoonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.green,
    this.leading,
    this.height = 52,
    this.fontSize = 17,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final String? leading;
  final double height;
  final double fontSize;

  @override
  State<CartoonButton> createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<CartoonButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final base = enabled ? widget.color : const Color(0xFF9E9E9E);
    final dark = darken(base, .22);

    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(widget.leading!, style: TextStyle(fontSize: widget.fontSize + 3)),
            ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: AppTheme.outline,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [lighten(base), base],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: dark, width: 3),
            boxShadow: [BoxShadow(color: dark, offset: Offset(0, _down ? 2 : 6))],
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
