class HistoryPoint {
  final String id;
  final DateTime timestamp;
  final double? temperatureC;
  final double? humidityPercent;
  final double? soilMoistureEstimatePercent;
  final int? soilAoRaw;
  final String soilStatus;
  final bool valid;

  HistoryPoint({
    required this.id,
    required this.timestamp,
    this.temperatureC,
    this.humidityPercent,
    this.soilMoistureEstimatePercent,
    this.soilAoRaw,
    this.soilStatus = 'UNKNOWN',
    this.valid = true,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    DateTime ts = DateTime.now();
    if (json['timestamp'] != null) {
      try {
        ts = DateTime.parse(json['timestamp'].toString());
      } catch (_) {}
    }

    return HistoryPoint(
      id: json['id']?.toString() ?? '',
      timestamp: ts,
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      humidityPercent: (json['humidity_percent'] as num?)?.toDouble(),
      soilMoistureEstimatePercent: (json['soil_moisture_estimate_percent'] as num?)?.toDouble(),
      soilAoRaw: (json['soil_ao_raw'] as num?)?.toInt(),
      soilStatus: json['soil_status']?.toString() ?? 'UNKNOWN',
      valid: json['valid'] == true,
    );
  }
}

class HistorySummary {
  final int count;
  final double windowHours;
  final double? tempMin;
  final double? tempMax;
  final double? tempAvg;
  final double? humidityMin;
  final double? humidityMax;
  final double? humidityAvg;
  final double? moistureMin;
  final double? moistureMax;
  final double? moistureAvg;

  HistorySummary({
    required this.count,
    required this.windowHours,
    this.tempMin,
    this.tempMax,
    this.tempAvg,
    this.humidityMin,
    this.humidityMax,
    this.humidityAvg,
    this.moistureMin,
    this.moistureMax,
    this.moistureAvg,
  });

  factory HistorySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HistorySummary(count: 0, windowHours: 24.0);

    final t = json['temperature'] as Map<String, dynamic>?;
    final h = json['humidity'] as Map<String, dynamic>?;
    final m = json['soil_moisture'] as Map<String, dynamic>?;

    return HistorySummary(
      count: (json['count'] as num?)?.toInt() ?? 0,
      windowHours: (json['window_hours'] as num?)?.toDouble() ?? 24.0,
      tempMin: (t?['min'] as num?)?.toDouble(),
      tempMax: (t?['max'] as num?)?.toDouble(),
      tempAvg: (t?['avg'] as num?)?.toDouble(),
      humidityMin: (h?['min'] as num?)?.toDouble(),
      humidityMax: (h?['max'] as num?)?.toDouble(),
      humidityAvg: (h?['avg'] as num?)?.toDouble(),
      moistureMin: (m?['min'] as num?)?.toDouble(),
      moistureMax: (m?['max'] as num?)?.toDouble(),
      moistureAvg: (m?['avg'] as num?)?.toDouble(),
    );
  }
}

class HistoryResponse {
  final HistorySummary summary;
  final List<HistoryPoint> records;

  HistoryResponse({required this.summary, required this.records});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>?;
    final recordsRaw = json['records'] as List<dynamic>? ?? [];

    final pts = recordsRaw
        .whereType<Map<String, dynamic>>()
        .map((r) => HistoryPoint.fromJson(r))
        .toList();

    return HistoryResponse(
      summary: HistorySummary.fromJson(summaryJson),
      records: pts,
    );
  }
}
