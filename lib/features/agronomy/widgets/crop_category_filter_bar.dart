import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/crop_visuals.dart';
import '../../../providers/agronomy_provider.dart';

class CropCategoryFilterBar extends StatelessWidget {
  const CropCategoryFilterBar({super.key});

  static const List<Map<String, String>> categories = [
    {'id': 'All', 'label': 'All Crops (42)', 'emoji': '🌿'},
    {'id': 'Fruit', 'label': 'Fruits (17)', 'emoji': '🍎'},
    {'id': 'Cereal & Grain', 'label': 'Cereals (4)', 'emoji': '🌾'},
    {'id': 'Pulse & Legume', 'label': 'Pulses (8)', 'emoji': '🌱'},
    {'id': 'Cash Crop / Commercial', 'label': 'Cash Crops (6)', 'emoji': '🪴'},
    {'id': 'Vegetable & Spice', 'label': 'Vegetables (4)', 'emoji': '🥕'},
    {'id': 'Oilseed', 'label': 'Oilseeds (3)', 'emoji': '🌻'},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AgronomyProvider>(
      builder: (context, provider, _) {
        final selected = provider.selectedCategory;

        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selected == cat['id'];
              final color = isSelected ? CropVisuals.getCategoryColor(cat['id']) : Colors.grey.shade600;

              return ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                selectedColor: CropVisuals.getCategoryColor(cat['id']).withAlpha(30),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? CropVisuals.getCategoryColor(cat['id']) : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1.0,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['emoji']!, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      cat['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? CropVisuals.getCategoryColor(cat['id']) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => provider.setSelectedCategory(cat['id']!),
              );
            },
          ),
        );
      },
    );
  }
}
