import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/crop_visuals.dart';
import '../../../models/agronomy_models.dart';
import '../../../providers/agronomy_provider.dart';

class CropAlternativesChart extends StatelessWidget {
  final List<CropAlternative> alternatives;
  final String? selectedCategory;

  const CropAlternativesChart({
    super.key,
    required this.alternatives,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    String activeCat = selectedCategory ?? 'All';
    try {
      final provider = Provider.of<AgronomyProvider>(context, listen: true);
      activeCat = selectedCategory ?? provider.selectedCategory;
    } catch (_) {}

    final filtered = activeCat == 'All'
        ? alternatives
        : alternatives.where((a) => a.category.toLowerCase().contains(activeCat.toLowerCase())).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF7C3AED),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Alternative Viable Crops',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${filtered.length} candidates',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'No alternative crops in "$activeCat" for current soil & climate.\nTry another category or adjust weather sliders above.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            )
          else
            ...filtered.map((alt) {
              final pct = alt.suitabilityPercent;
              final normalized = (pct / 100.0).clamp(0.05, 1.0);
              final catColor = CropVisuals.getCategoryColor(alt.category);
              final catEmoji = CropVisuals.getCategoryEmoji(alt.category);
              final icon = CropVisuals.getCropIcon(alt.crop);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: catColor.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 14, color: catColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alt.displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$catEmoji ${alt.category}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: catColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(1)}% Match',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: catColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Horizontal animated bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: normalized,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      ),
                    ),

                    if (alt.farmerTip.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        alt.farmerTip,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
