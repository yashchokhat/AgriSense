import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/history_response.dart';

class SensorChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color lineColor;
  final List<HistoryPoint> records;
  final double? Function(HistoryPoint) valueSelector;
  final double? minVal;
  final double? maxVal;
  final double? avgVal;

  const SensorChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.lineColor,
    required this.records,
    required this.valueSelector,
    this.minVal,
    this.maxVal,
    this.avgVal,
  });

  @override
  Widget build(BuildContext context) {
    final validPoints = <FlSpot>[];
    for (int i = 0; i < records.length; i++) {
      final val = valueSelector(records[i]);
      if (val != null) {
        validPoints.add(FlSpot(i.toDouble(), val));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: lineColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: lineColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Min, Avg, Max stats row
            if (minVal != null && maxVal != null && avgVal != null) ...[
              Row(
                children: [
                  _statPill('Min', '${minVal!.toStringAsFixed(1)}$unit', AppColors.textSecondary),
                  const SizedBox(width: 8),
                  _statPill('Avg', '${avgVal!.toStringAsFixed(1)}$unit', AppColors.textPrimary),
                  const SizedBox(width: 8),
                  _statPill('Max', '${maxVal!.toStringAsFixed(1)}$unit', lineColor),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Chart area
            SizedBox(
              height: 180,
              child: validPoints.length < 2
                  ? Center(
                      child: Text(
                        'Awaiting more historical data points...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 10,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppColors.divider.withOpacity(0.5),
                            strokeWidth: 0.8,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (val, meta) => Text(
                                val.toInt().toString(),
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: (records.length / 3).clamp(1.0, 100.0),
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < records.length) {
                                  return Text(
                                    DateFormat('HH:mm').format(records[idx].timestamp.toLocal()),
                                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: validPoints,
                            isCurved: true,
                            curveSmoothness: 0.25,
                            color: lineColor,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: validPoints.length < 15,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: lineColor,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: lineColor.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.textMuted)),
            TextSpan(text: value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
