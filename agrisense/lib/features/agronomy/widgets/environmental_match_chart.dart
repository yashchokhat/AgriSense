import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/agronomy_models.dart';

class EnvironmentalMatchChart extends StatelessWidget {
  final List<FactorAnalysis> factors;

  const EnvironmentalMatchChart({
    super.key,
    required this.factors,
  });

  @override
  Widget build(BuildContext context) {
    // Filter down to the 3 key IoT sensor parameters: Moisture, Temperature, Humidity
    final sensorFactors = factors.where((f) {
      final name = f.parameter.toLowerCase();
      return name.contains('moisture') || name.contains('temperature') || name.contains('humidity');
    }).toList();

    if (sensorFactors.isEmpty) {
      return const SizedBox.shrink();
    }

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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'IoT Sensor vs Crop Ideal Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Legend Pill
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(const Color(0xFF10B981), 'Live'),
                  const SizedBox(width: 8),
                  _legendDot(const Color(0xFF94A3B8), 'Target'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Compares ESP32 real-time field readings against optimum crop threshold.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),

          // fl_chart Bar Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex >= sensorFactors.length) return null;
                      final f = sensorFactors[groupIndex];
                      final isCurrent = rodIndex == 0;
                      final title = isCurrent ? 'Live: ${f.current}' : 'Ideal: ${f.idealRange}';
                      return BarTooltipItem(
                        '${f.parameter}\n$title',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sensorFactors.length) {
                          return const SizedBox.shrink();
                        }
                        final label = _shortenParam(sensorFactors[idx].parameter);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(sensorFactors.length, (i) {
                  final f = sensorFactors[i];
                  final currentVal = (f.currentNum ?? _extractFirstNumber(f.current)).clamp(0.0, 100.0);
                  final idealMid = f.idealMin != null && f.idealMax != null
                      ? ((f.idealMin! + f.idealMax!) / 2.0).clamp(0.0, 100.0)
                      : _extractMidNumber(f.idealRange).clamp(0.0, 100.0);

                  final isOk = f.isFavorable;
                  final currentColor = isOk ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      // Rod 1: Live reading
                      BarChartRodData(
                        toY: currentVal,
                        color: currentColor,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      // Rod 2: Ideal Center Target
                      BarChartRodData(
                        toY: idealMid,
                        color: const Color(0xFFCBD5E1),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Status Pill Cards
          Column(
            children: sensorFactors.map((f) {
              final isOk = f.isFavorable;
              final color = isOk ? const Color(0xFF059669) : const Color(0xFFD97706);
              final bg = isOk ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOk ? Icons.check_circle_rounded : Icons.info_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${f.parameter}: ${f.current}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      'Ideal: ${f.idealRange}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _shortenParam(String p) {
    final lower = p.toLowerCase();
    if (lower.contains('moisture')) return 'Moisture';
    if (lower.contains('temp')) return 'Temp';
    if (lower.contains('humidity')) return 'Humidity';
    if (lower.contains('ph')) return 'pH';
    return p;
  }

  double _extractFirstNumber(String s) {
    final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(s);
    if (match != null) {
      return double.tryParse(match.group(0) ?? '') ?? 0.0;
    }
    return 0.0;
  }

  double _extractMidNumber(String s) {
    final matches = RegExp(r'[-+]?\d*\.?\d+').allMatches(s).toList();
    if (matches.length >= 2) {
      final a = double.tryParse(matches[0].group(0) ?? '') ?? 0.0;
      final b = double.tryParse(matches[1].group(0) ?? '') ?? 0.0;
      return (a + b) / 2.0;
    } else if (matches.length == 1) {
      return double.tryParse(matches[0].group(0) ?? '') ?? 0.0;
    }
    return 50.0;
  }
}
