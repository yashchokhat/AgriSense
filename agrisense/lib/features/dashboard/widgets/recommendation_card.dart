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
    Color cardColor;
    Color accentColor;
    IconData icon;

    if (recommendation.irrigationNeeded == true) {
      if (recommendation.urgency == 'CRITICAL') {
        cardColor = const Color(0xFFFEF2F2);
        accentColor = AppColors.critical;
        icon = Icons.water_drop_rounded;
      } else {
        cardColor = const Color(0xFFFFFBEB);
        accentColor = AppColors.warning;
        icon = Icons.water_drop_outlined;
      }
    } else {
      cardColor = const Color(0xFFF0FDF4);
      accentColor = AppColors.online;
      icon = Icons.check_circle_outline_rounded;
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withOpacity(0.25), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        recommendation.isMlBased ? Icons.auto_awesome : Icons.rule,
                        size: 12,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recommendation.isMlBased ? 'ML MODEL' : 'RULE-BASED',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
            if (recommendation.confidence != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Prediction Confidence: ${(recommendation.confidence! * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const Spacer(),
                  if (onTapInsights != null)
                    InkWell(
                      onTap: onTapInsights,
                      child: Row(
                        children: [
                          Text(
                            'View Insights',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 16, color: accentColor),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
