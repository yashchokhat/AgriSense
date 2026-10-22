import 'device_status.dart';
import 'sensor_reading.dart';
import 'prediction.dart';
import 'alert_item.dart';

class DashboardData {
  final DeviceStatus device;
  final SensorReading telemetry;
  final Prediction recommendation;
  final List<AlertItem> alerts;
  final int totalAlertsCount;
  final int criticalAlertsCount;
  final Map<String, dynamic>? trends24h;

  DashboardData({
    required this.device,
    required this.telemetry,
    required this.recommendation,
    this.alerts = const [],
    this.totalAlertsCount = 0,
    this.criticalAlertsCount = 0,
    this.trends24h,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final devJson = json['device'] as Map<String, dynamic>?;
    final telJson = json['telemetry'] as Map<String, dynamic>?;
    final recJson = json['recommendation'] as Map<String, dynamic>?;
    final alertSummary = json['alerts_summary'] as Map<String, dynamic>? ?? {};

    final alertItemsRaw = alertSummary['items'] as List<dynamic>? ?? [];
    final alertList = alertItemsRaw
        .whereType<Map<String, dynamic>>()
        .map((a) => AlertItem.fromJson(a))
        .toList();

    return DashboardData(
      device: DeviceStatus.fromJson(devJson),
      telemetry: SensorReading.fromJson(telJson),
      recommendation: Prediction.fromJson(recJson),
      alerts: alertList,
      totalAlertsCount: (alertSummary['count'] as num?)?.toInt() ?? alertList.length,
      criticalAlertsCount: (alertSummary['critical_count'] as num?)?.toInt() ?? 0,
      trends24h: json['trends_24h'] as Map<String, dynamic>?,
    );
  }
}
