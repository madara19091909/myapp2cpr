import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cartoon_button.dart';
import '../../../core/widgets/toast.dart';
import '../../game/state/game_state.dart';
import '../../shop/data/shop_data.dart';

class SeedPicker extends StatelessWidget {
  const SeedPicker({super.key, required this.plotIndex});

  final int plotIndex;

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    final owned = ShopData.crops.where((c) => g.ownedSeeds(c.id) > 0).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.soilDark, width: 4)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر بذرة للزراعة 🌱',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.dark)),
            const SizedBox(height: 12),
            if (owned.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('لا تملك أي بذور!\nاذهب إلى متجر البذور واشترِ بعضها 🛒',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: owned.length,
                  itemBuilder: (context, i) {
                    final crop = owned[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: CartoonButton(
                        color: AppColors.orange,
                        leading: crop.emoji,
                        label: '${crop.name}  (×${g.ownedSeeds(crop.id)})',
                        height: 50,
                        onPressed: () {
                          final ok = context.read<GameState>().plant(plotIndex, crop);
                          Navigator.of(context).pop();
                          if (ok) showToast(context, 'تمت زراعة ${crop.name} ${crop.emoji}', color: AppColors.green);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
