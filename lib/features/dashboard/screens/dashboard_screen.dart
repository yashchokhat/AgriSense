import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/soil_moisture_gauge.dart';
import '../widgets/metric_card.dart';
import '../widgets/recommendation_card.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToAlerts;
  final VoidCallback? onNavigateToInsights;
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToAgronomy;

  const DashboardScreen({
    super.key,
    this.onNavigateToAlerts,
    this.onNavigateToInsights,
    this.onNavigateToSettings,
    this.onNavigateToAgronomy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<SettingsProvider>(
              builder: (_, settings, _) => Text(
                settings.farmName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Text(
              'AgriSense IoT Platform',
              style: TextStyle(fontSize: 12, color: AppColors.highlight),
            ),
          ],
        ),
        actions: [
          Consumer<SensorProvider>(
            builder: (_, provider, _) {
              final count = provider.dashboard?.totalAlertsCount ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Alerts',
                    onPressed: onNavigateToAlerts,
                  ),
                  if (count > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.critical,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onNavigateToSettings,
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDashboard && provider.dashboard == null) {
            return const LoadingIndicator(message: 'Connecting to AgriSense live sensors...');
          }

          if (provider.errorMessage != null && provider.dashboard == null) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchDashboard(isInitial: true),
              onOpenSettings: onNavigateToSettings,
            );
          }

          final data = provider.dashboard;
          if (data == null) {
            return ErrorView(
              message: 'No sensor telemetry available.',
              onRetry: () => provider.fetchDashboard(isInitial: true),
            );
          }

          final telemetry = data.telemetry;
          final device = data.device;
          final recommendation = data.recommendation;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.refreshAll(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Connectivity & Telemetry freshness banner
                ConnectivityBanner(
                  device: device,
                  onRefresh: () => provider.fetchDashboard(silent: false),
                ),
                const SizedBox(height: 16),

                // Active alerts banner if critical
                if (data.criticalAlertsCount > 0) ...[
                  InkWell(
                    onTap: onNavigateToAlerts,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.critical.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.critical, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${data.criticalAlertsCount} critical alert(s) require attention.',
                              style: const TextStyle(
                                color: AppColors.critical,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.critical),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Soil Moisture Gauge (Primary)
                SoilMoistureGauge(reading: telemetry),
                const SizedBox(height: 16),

                // Recommendation Card (Irrigation AI)
                RecommendationCard(
                  recommendation: recommendation,
                  onTapInsights: onNavigateToInsights,
                ),
                const SizedBox(height: 16),

                // Crop & Fertilizer Advisory Quick Card (Kaggle ML Models)
                if (data.agronomy != null) ...[
                  InkWell(
                    onTap: onNavigateToAgronomy,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.green.shade200, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.psychology_rounded, color: Color(0xFF059669), size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Crop & Fertilizer ML Engine',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View Graphs',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade100),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'BEST CROP FOR SOIL',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF15803D), letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data.agronomy!.cropRecommendation.displayName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: (data.agronomy!.cropRecommendation.suitabilityPercent / 100.0).clamp(0.05, 1.0),
                                                minHeight: 4,
                                                backgroundColor: Colors.green.shade100,
                                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${data.agronomy!.cropRecommendation.suitabilityPercent.toStringAsFixed(0)}%',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade100),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'RECOMMENDED FERTILIZER',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309), letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data.agronomy!.fertilizerRecommendation.displayName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data.agronomy!.fertilizerRecommendation.recommendedDosage,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section Title: Environment Sensors
                Text(
                  'Atmospheric & Soil Readings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),

                // 2x2 Sensor Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    MetricCard(
                      title: 'TEMPERATURE',
                      value: telemetry.temperatureC != null
                          ? telemetry.temperatureC!.toStringAsFixed(1)
                          : '--',
                      unit: '°C',
                      icon: Icons.thermostat_rounded,
                      accentColor: AppColors.tempAccent,
                      backgroundColor: AppColors.tempCard,
                      statusText: telemetry.dhtValid ? 'DHT Valid' : 'Read Error',
                      statusColor: telemetry.dhtValid ? AppColors.online : AppColors.critical,
                    ),
                    MetricCard(
                      title: 'HUMIDITY',
                      value: telemetry.humidityPercent != null
                          ? telemetry.humidityPercent!.toStringAsFixed(1)
                          : '--',
                      unit: '%',
                      icon: Icons.water_drop_outlined,
                      accentColor: AppColors.humidityAccent,
                      backgroundColor: AppColors.humidityCard,
                      statusText: 'Relative RH',
                    ),
                    MetricCard(
                      title: 'RAW SOIL ADC',
                      value: telemetry.soilAoRaw != null ? '${telemetry.soilAoRaw}' : '--',
                      unit: 'ADC',
                      icon: Icons.analytics_outlined,
                      accentColor: AppColors.moistureAccent,
                      backgroundColor: AppColors.moistureCard,
                      subtitle: '12-bit (0-4095)',
                    ),
                    MetricCard(
                      title: 'DIGITAL THRESHOLD',
                      value: telemetry.soilDo != null ? 'DO: ${telemetry.soilDo}' : '--',
                      unit: '',
                      icon: Icons.toggle_on_outlined,
                      accentColor: AppColors.primary,
                      backgroundColor: AppColors.highlight,
                      statusText: telemetry.soilStatus,
                      statusColor: telemetry.soilStatus == 'DRY'
                          ? AppColors.soilDry
                          : (telemetry.soilStatus == 'WET' ? AppColors.soilWet : AppColors.soilOptimal),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
