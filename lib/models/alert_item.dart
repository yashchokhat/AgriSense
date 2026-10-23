class AlertItem {
  final String id;
  final String severity; // CRITICAL, WARNING, INFO, ERROR
  final String title;
  final String message;
  final String category;
  final DateTime? timestamp;
  final dynamic sensorValue;
  final String? unit;
  final bool acknowledged;

  AlertItem({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    this.category = 'GENERAL',
    this.timestamp,
    this.sensorValue,
    this.unit,
    this.acknowledged = false,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    DateTime? ts;
    if (json['timestamp'] != null) {
      try {
        ts = DateTime.parse(json['timestamp'].toString());
      } catch (_) {}
    }

    return AlertItem(
      id: json['id']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'INFO',
      title: json['title']?.toString() ?? 'Alert',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      timestamp: ts,
      sensorValue: json['sensor_value'],
      unit: json['unit']?.toString(),
      acknowledged: json['acknowledged'] == true,
    );
  }
}
