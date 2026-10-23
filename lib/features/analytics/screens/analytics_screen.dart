import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/sensor_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../widgets/sensor_chart_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Analytics & Trends'),
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          final historyData = provider.history;
          final records = historyData?.records ?? [];
          final summary = historyData?.summary;
          final selectedHours = provider.selectedHistoryHours;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.fetchHistory(hours: selectedHours),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Time Range Selector Filter
                Row(
                  children: [
                    const Text(
                      'Time Window: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(context, provider, '6 Hours', 6.0, selectedHours),
                    const SizedBox(width: 8),
                    _filterChip(context, provider, '24 Hours', 24.0, selectedHours),
                    const SizedBox(width: 8),
                    _filterChip(context, provider, '7 Days', 168.0, selectedHours),
                  ],
                ),
                const SizedBox(height: 16),

                if (provider.isLoadingHistory && records.isEmpty)
                  const SizedBox(
                    height: 250,
                    child: LoadingIndicator(message: 'Loading sensor records...'),
                  )
                else if (records.isEmpty)
                  const EmptyStateView(
                    title: 'No Historical Records Found',
                    message:
                        'The ESP32 has recently begun streaming. Historical records will accumulate here as readings are ingested.',
                    icon: Icons.timeline_rounded,
                  )
                else ...[
                  // 1. Soil Moisture Chart
                  SensorChartCard(
                    title: 'Soil Moisture Level',
                    unit: '%',
                    lineColor: AppColors.soilOptimal,
                    records: records,
                    valueSelector: (r) => r.soilMoistureEstimatePercent,
                    minVal: summary?.moistureMin,
                    maxVal: summary?.moistureMax,
                    avgVal: summary?.moistureAvg,
                  ),
                  const SizedBox(height: 16),

                  // 2. Temperature Chart
                  SensorChartCard(
                    title: 'Ambient Temperature',
                    unit: '°C',
                    lineColor: AppColors.tempAccent,
                    records: records,
                    valueSelector: (r) => r.temperatureC,
                    minVal: summary?.tempMin,
                    maxVal: summary?.tempMax,
                    avgVal: summary?.tempAvg,
                  ),
                  const SizedBox(height: 16),

                  // 3. Humidity Chart
                  SensorChartCard(
                    title: 'Relative Humidity',
                    unit: '%',
                    lineColor: AppColors.info,
                    records: records,
                    valueSelector: (r) => r.humidityPercent,
                    minVal: summary?.humidityMin,
                    maxVal: summary?.humidityMax,
                    avgVal: summary?.humidityAvg,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    SensorProvider provider,
    String label,
    double hours,
    double selectedHours,
  ) {
    final isSelected = selectedHours == hours;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          provider.fetchHistory(hours: hours);
        }
      },
      selectedColor: AppColors.highlight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
