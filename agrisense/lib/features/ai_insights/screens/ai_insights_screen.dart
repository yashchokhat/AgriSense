import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';

class AiInsightsScreen extends StatelessWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation Intelligence'),
      ),
      body: Consumer2<SensorProvider, SettingsProvider>(
        builder: (context, sensorProv, settingsProv, child) {
          final rec = sensorProv.dashboard?.recommendation;

          if (sensorProv.isLoadingDashboard && rec == null) {
            return const LoadingIndicator(message: 'Evaluating agronomic models...');
          }

          if (rec == null || !rec.available) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assessment_outlined, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'Irrigation Analysis Unavailable',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Awaiting live telemetry or model initialization to run inference.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => sensorProv.fetchDashboard(silent: false),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Analysis'),
                    ),
                  ],
                ),
              ),
            );
          }

          final isNeeded = rec.irrigationNeeded ?? false;
          final isMl = rec.isMlBased;

          Color bannerColor = isNeeded ? AppColors.warning : AppColors.online;
          if (rec.urgency == 'CRITICAL') bannerColor = AppColors.critical;

          final timeStr = rec.timestamp != null
              ? DateFormat('MMM dd, yyyy · HH:mm:ss').format(rec.timestamp!.toLocal())
              : 'Recent';

          final confidenceVal = rec.confidence != null
              ? (rec.confidence! * 100.0).clamp(0.0, 100.0)
              : null;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => sensorProv.fetchDashboard(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // 1. Primary Recommendation Hero Card
                Card(
                  color: bannerColor.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: bannerColor.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bannerColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isNeeded ? Icons.water_drop_rounded : Icons.check_circle_rounded,
                                color: bannerColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.title,
                                    style: TextStyle(
                                      color: bannerColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Evaluated at $timeStr',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          rec.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tags & Confidence Badge
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _badge(
                              icon: isMl ? Icons.model_training_rounded : Icons.rule_rounded,
                              label: isMl ? 'Random Forest Model' : 'FAO-56 Agronomic Rules',
                              color: AppColors.primary,
                            ),
                            _badge(
                              icon: Icons.shield_outlined,
                              label: 'Urgency: ${rec.urgency}',
                              color: bannerColor,
                            ),
                            if (confidenceVal != null)
                              _badge(
                                icon: Icons.straighten_rounded,
                                label: 'Confidence: ${confidenceVal.toStringAsFixed(1)}%',
                                color: AppColors.primaryLight,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Factor Explanations Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Agronomic Decision Factors',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (rec.explanation.isEmpty)
                          const Text(
                            'Decision based on nominal baseline thresholds.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          )
                        else
                          ...rec.explanation.map(
                            (factor) => Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0, right: 8.0),
                                    child: Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                                  ),
                                  Expanded(
                                    child: Text(
                                      factor,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Feature Breakdown
                if (rec.featuresUsed.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Telemetry Features Input to Pipeline',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                rec.modelVersion ?? '',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _featureRow('Soil Moisture Estimate', '${rec.featuresUsed["soil_moisture_estimate_percent"] ?? "--"}%'),
                          const Divider(height: 14),
                          _featureRow('Ambient Temperature', '${rec.featuresUsed["temperature_c"] ?? "--"}°C'),
                          const Divider(height: 14),
                          _featureRow('Relative Humidity', '${rec.featuresUsed["humidity_percent"] ?? "--"}%'),
                          const Divider(height: 14),
                          _featureRow('Vapor Pressure Deficit (VPD)', '${rec.featuresUsed["vpd_kpa"] ?? "--"} kPa'),
                          const Divider(height: 14),
                          _featureRow('Crop Variety Context', '${rec.featuresUsed["crop_type"] ?? "general"}'.toUpperCase()),
                          const Divider(height: 14),
                          _featureRow('Soil Texture Context', '${rec.featuresUsed["soil_type"] ?? "loam"}'.toUpperCase()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Trigger Live Inference Button
                ElevatedButton.icon(
                  onPressed: sensorProv.isRunningInference
                      ? null
                      : () => sensorProv.runImmediateInference(),
                  icon: sensorProv.isRunningInference
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    sensorProv.isRunningInference
                        ? 'Running Model Inference...'
                        : 'Re-evaluate with Current Telemetry',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
