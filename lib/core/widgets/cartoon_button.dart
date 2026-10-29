import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

Color darken(Color c, [double amount = .18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0).toDouble()).toColor();
}

Color lighten(Color c, [double amount = .12]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0).toDouble()).toColor();
}

/// زر كرتوني ثلاثي الأبعاد مع حركة ضغط ولمس أوضح.
class CartoonButton extends StatefulWidget {
  const CartoonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.green,
    this.leading,
    this.height = 54,
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
    final dark = darken(base, .24);

    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading != null)
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text(widget.leading!, style: TextStyle(fontSize: widget.fontSize + 4)),
            ),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
              shadows: AppTheme.outline,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled
          ? (_) {
              setState(() => _down = true);
              HapticFeedback.selectionClick();
            }
          : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 85),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _down ? 5 : 0, 0),
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [lighten(base, .16), base, darken(base, .06)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dark, width: 3.2),
            boxShadow: [
              BoxShadow(color: dark, offset: Offset(0, _down ? 2 : 7)),
              if (!_down)
                BoxShadow(
                  color: base.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
