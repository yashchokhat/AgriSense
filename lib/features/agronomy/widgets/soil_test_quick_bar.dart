import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/agronomy_models.dart';

class SoilTestQuickBar extends StatelessWidget {
  final SoilProfile soil;
  final VoidCallback onEdit;

  const SoilTestQuickBar({
    super.key,
    required this.soil,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: Color(0xFF0D9488),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soil Test Nutrients',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      soil.isManuallyEntered ? 'Manual Lab Test' : 'Agronomic Baseline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: soil.isManuallyEntered ? const Color(0xFF0F766E) : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_rounded, size: 14),
                label: const Text('Edit NPK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withAlpha(20),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4 Compact Pills: N, P, K, pH
          Row(
            children: [
              _buildNutrientPill('N', '${soil.nitrogen.toStringAsFixed(0)}', 'kg/ha', const Color(0xFF2563EB)),
              const SizedBox(width: 6),
              _buildNutrientPill('P', '${soil.phosphorus.toStringAsFixed(0)}', 'kg/ha', const Color(0xFFEA580C)),
              const SizedBox(width: 6),
              _buildNutrientPill('K', '${soil.potassium.toStringAsFixed(0)}', 'kg/ha', const Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              _buildNutrientPill('pH', soil.ph.toStringAsFixed(1), 'scale', const Color(0xFF0D9488)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientPill(String name, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
