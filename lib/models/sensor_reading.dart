class SensorReading {
  final DateTime? timestamp;
  final double? temperatureC;
  final double? humidityPercent;
  final double? soilMoistureEstimatePercent;
  final int? soilAoRaw;
  final int? soilDo;
  final String soilStatus;
  final bool dhtValid;
  final bool soilValid;
  final bool allValid;
  final List<String> warnings;

  SensorReading({
    this.timestamp,
    this.temperatureC,
    this.humidityPercent,
    this.soilMoistureEstimatePercent,
    this.soilAoRaw,
    this.soilDo,
    this.soilStatus = 'UNKNOWN',
    this.dhtValid = false,
    this.soilValid = false,
    this.allValid = false,
    this.warnings = const [],
  });

  factory SensorReading.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SensorReading();

    final calibrated = json['calibrated'] as Map<String, dynamic>? ?? {};
    final raw = json['raw'] as Map<String, dynamic>? ?? {};
    final quality = json['quality'] as Map<String, dynamic>? ?? {};
    final threshold = json['threshold_status'] as Map<String, dynamic>? ?? {};

    DateTime? ts;
    if (json['timestamp'] != null) {
      try {
        ts = DateTime.parse(json['timestamp'].toString());
      } catch (_) {}
    }

    final rawWarnings = quality['warnings'] as List<dynamic>?;
    final warningList = rawWarnings?.map((w) => w.toString()).toList() ?? <String>[];

    return SensorReading(
      timestamp: ts,
      temperatureC: (calibrated['temperature_c'] as num?)?.toDouble(),
      humidityPercent: (calibrated['humidity_percent'] as num?)?.toDouble(),
      soilMoistureEstimatePercent: (calibrated['soil_moisture_estimate_percent'] as num?)?.toDouble(),
      soilAoRaw: (raw['soil_ao_raw'] as num?)?.toInt(),
      soilDo: (raw['soil_do'] as num?)?.toInt(),
      soilStatus: threshold['soil_status']?.toString() ?? 'UNKNOWN',
      dhtValid: quality['dht_valid'] == true,
      soilValid: quality['soil_valid'] == true,
      allValid: quality['all_valid'] == true,
      warnings: warningList,
    );
  }
}
