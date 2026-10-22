import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';

class SoilMoistureGauge extends StatelessWidget {
  final SensorReading reading;

  const SoilMoistureGauge({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final moisture = reading.soilMoistureEstimatePercent ?? 0.0;
    final rawAdc = reading.soilAoRaw ?? 0;
    final status = reading.soilStatus.toUpperCase();

    Color statusColor;
    if (status == 'DRY') {
      statusColor = AppColors.soilDry;
    } else if (status == 'WET') {
      statusColor = AppColors.soilWet;
    } else {
      statusColor = AppColors.soilOptimal;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.grass_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soil Moisture Level',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Capacitive / Resistive Sensor',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Circular Progress Gauge
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(
                          value: (moisture / 100.0).clamp(0.0, 1.0),
                          strokeWidth: 9.0,
                          backgroundColor: AppColors.divider.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${moisture.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            'Vol. Est',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Detailed Breakdown Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Calibrated Estimate', '${moisture.toStringAsFixed(1)}%'),
                      const Divider(height: 16),
                      _buildInfoRow('Raw 12-bit ADC', '$rawAdc / 4095'),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Digital Threshold (DO)',
                        reading.soilDo == 0 ? 'Active (Moist)' : 'Inactive (Dry)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
