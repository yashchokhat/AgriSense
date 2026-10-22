class DeviceStatus {
  final String deviceId;
  final bool isOnline;
  final bool isStale;
  final DateTime? lastSeenTimestamp;
  final double secondsSinceLastSeen;
  final int? wifiRssiDbm;
  final String wifiQuality;
  final int uptimeMs;

  DeviceStatus({
    required this.deviceId,
    required this.isOnline,
    required this.isStale,
    this.lastSeenTimestamp,
    this.secondsSinceLastSeen = 0.0,
    this.wifiRssiDbm,
    required this.wifiQuality,
    this.uptimeMs = 0,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DeviceStatus(
        deviceId: 'UNKNOWN',
        isOnline: false,
        isStale: true,
        wifiQuality: 'OFFLINE',
      );
    }

    DateTime? lastSeen;
    if (json['last_seen_timestamp'] != null) {
      try {
        lastSeen = DateTime.parse(json['last_seen_timestamp'].toString());
      } catch (_) {}
    }

    return DeviceStatus(
      deviceId: json['device_id']?.toString() ?? 'ESP32_AGRISENSE_01',
      isOnline: json['is_online'] == true,
      isStale: json['is_stale'] == true,
      lastSeenTimestamp: lastSeen,
      secondsSinceLastSeen: (json['seconds_since_last_seen'] as num?)?.toDouble() ?? 0.0,
      wifiRssiDbm: (json['wifi_rssi_dbm'] as num?)?.toInt(),
      wifiQuality: json['wifi_quality']?.toString() ?? 'UNKNOWN',
      uptimeMs: (json['uptime_ms'] as num?)?.toInt() ?? 0,
    );
  }
}
