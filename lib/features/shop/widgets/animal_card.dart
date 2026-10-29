import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/cartoon_card.dart';
import '../../../core/widgets/ticker_builder.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../models/animal.dart';
import 'emoji_badge.dart';

class AnimalCard extends StatelessWidget {
  const AnimalCard({super.key, required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final owned = g.ownedAnimals(animal.id);

    return CartoonCard(
      child: Column(
        children: [
          Row(
            children: [
              EmojiBadge(animal.emoji),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animal.name,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark)),
                    Text('السعر: ${formatIqd(animal.price)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                      animal.isProductive
                          ? 'ينتج ${formatIqd(animal.incomePerCycle)} كل ${animal.cycleSeconds} ثانية'
                          : 'يزيد أرباح الحصاد +${animal.petBonusPercent}%',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    InfoChip('تملك $owned', color: AppColors.purple),
                    if (animal.isProductive && owned > 0 && g.boostedCycles(animal.id) > 0) ...[
                      const SizedBox(height: 4),
                      InfoChip('تعزيز الإنتاج: ${g.boostedCycles(animal.id)} دورات', color: AppColors.green),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: owned > 0 || animal.isProductive ? 112 : double.infinity,
                child: CartoonButton(
                  color: AppColors.green,
                  leading: '🛒',
                  label: 'شراء',
                  onPressed: () {
                    final err = context.read<GameState>().buyAnimal(animal);
                    showToast(context, err ?? 'تم شراء ${animal.name} ${animal.emoji}',
                        color: err == null ? AppColors.green : AppColors.red);
                  },
                ),
              ),
              if (owned > 0)
                SizedBox(
                  width: 142,
                  child: CartoonButton(
                    color: AppColors.red,
                    leading: '💰',
                    label: 'بيع ${formatIqd((animal.price * 0.5).floor())}',
                    onPressed: () {
                      final err = context.read<GameState>().sellAnimal(animal);
                      showToast(context, err ?? 'تم بيع ${animal.name} واسترداد ${formatIqd((animal.price * 0.5).floor())}',
                          color: err == null ? AppColors.green : AppColors.red);
                    },
                  ),
                ),
              if (animal.isProductive && owned > 0)
                SizedBox(
                  width: 126,
                  child: CartoonButton(
                    color: AppColors.purple,
                    leading: '🌾',
                    label: 'إطعام ($owned)',
                    onPressed: () {
                      final error = context.read<GameState>().feedAnimal(animal);
                      showToast(context, error ?? 'تم إطعام ${animal.name} وتعزيز إنتاجه 50% لثلاث دورات',
                          color: error == null ? AppColors.green : AppColors.red);
                    },
                  ),
                ),
              if (animal.isProductive)
                SizedBox(
                  width: 126,
                  child: TickerBuilder(
                    builder: (context, now) {
                      final pending = g.pendingIncome(animal, now);
                      return CartoonButton(
                        color: AppColors.orange,
                        leading: '🧺',
                        label: pending > 0 ? formatIqd(pending) : 'جمع',
                        onPressed: pending > 0
                            ? () {
                                final got = context.read<GameState>().collectAnimal(animal);
                                showToast(context, '+${formatIqd(got)}', color: AppColors.green);
                              }
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
