import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LiveIoTMetricsBar extends StatelessWidget {
  final Map<String, dynamic> environment;
  final bool isLiveIot;

  const LiveIoTMetricsBar({
    super.key,
    required this.environment,
    required this.isLiveIot,
  });

  @override
  Widget build(BuildContext context) {
    final temp = (environment['temperature_c'] as num?)?.toDouble() ?? 28.0;
    final hum = (environment['humidity_percent'] as num?)?.toDouble() ?? 60.0;
    final moist = (environment['soil_moisture_estimate_percent'] as num?)?.toDouble() ?? 40.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isLiveIot ? AppColors.accent.withAlpha(80) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Live Indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isLiveIot ? const Color(0xFF10B981) : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isLiveIot ? 'LIVE ESP32 SENSORS' : 'STREAMED TELEMETRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isLiveIot ? const Color(0xFF047857) : Colors.blue.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLiveIot ? const Color(0xFFECFDF5) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isLiveIot ? 'Connected' : 'Cached',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isLiveIot ? const Color(0xFF059669) : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Metric Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Moisture',
                  value: '${moist.toStringAsFixed(0)}%',
                  status: _getMoistureStatus(moist),
                  statusColor: _getMoistureColor(moist),
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: '${temp.toStringAsFixed(1)}°C',
                  status: _getTempStatus(temp),
                  statusColor: _getTempColor(temp),
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.air_rounded,
                  label: 'Humidity',
                  value: '${hum.toStringAsFixed(0)}%',
                  status: _getHumStatus(hum),
                  statusColor: _getHumColor(hum),
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoistureStatus(double m) {
    if (m < 30) return 'Dry';
    if (m <= 75) return 'Optimal';
    return 'Wet';
  }

  Color _getMoistureColor(double m) {
    if (m < 30) return const Color(0xFFF59E0B);
    if (m <= 75) return const Color(0xFF10B981);
    return const Color(0xFF3B82F6);
  }

  String _getTempStatus(double t) {
    if (t < 18) return 'Cool';
    if (t <= 32) return 'Optimal';
    return 'Hot';
  }

  Color _getTempColor(double t) {
    if (t < 18) return const Color(0xFF3B82F6);
    if (t <= 32) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  String _getHumStatus(double h) {
    if (h < 40) return 'Low';
    if (h <= 80) return 'Optimal';
    return 'High';
  }

  Color _getHumColor(double h) {
    if (h < 40) return const Color(0xFFF59E0B);
    if (h <= 80) return const Color(0xFF10B981);
    return const Color(0xFF3B82F6);
  }
}
