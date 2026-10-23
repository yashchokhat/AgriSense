import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/prediction.dart';

class RecommendationCard extends StatelessWidget {
  final Prediction recommendation;
  final VoidCallback? onTapInsights;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTapInsights,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBg;
    Color accentColor;
    IconData icon;

    if (recommendation.irrigationNeeded == true) {
      if (recommendation.urgency == 'CRITICAL') {
        cardBg = const Color(0xFFFEF2F2);
        accentColor = AppColors.critical;
        icon = Icons.water_drop_rounded;
      } else {
        cardBg = const Color(0xFFFFFBEB);
        accentColor = AppColors.warning;
        icon = Icons.water_drop_outlined;
      }
    } else {
      cardBg = const Color(0xFFF0FDF4);
      accentColor = AppColors.online;
      icon = Icons.check_circle_outline_rounded;
    }

    final confidencePct = recommendation.confidence != null
        ? (recommendation.confidence! * 100.0).clamp(0.0, 100.0)
        : null;

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        recommendation.isMlBased ? Icons.analytics_outlined : Icons.rule_rounded,
                        size: 11,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recommendation.isMlBased ? 'ML MODEL' : 'RULE-BASED',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              recommendation.message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            if (confidencePct != null) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Model Confidence',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${confidencePct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidencePct / 100.0,
                      minHeight: 4.5,
                      backgroundColor: Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ],
              ),
            ],
            if (onTapInsights != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onTapInsights,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detailed Factors',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: accentColor),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
