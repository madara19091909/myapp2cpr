import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class EmojiBadge extends StatelessWidget {
  const EmojiBadge(this.emoji, {super.key, this.size = 64});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * .55)),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.text, {super.key, this.color = AppColors.blue});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.wood,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline, width: 2),
            boxShadow: const [BoxShadow(color: AppColors.soilDark, offset: Offset(0, 4))],
          ),
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.dark, fontSize: 20, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
