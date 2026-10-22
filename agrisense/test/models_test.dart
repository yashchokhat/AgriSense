import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/models/sensor_reading.dart';
import 'package:agrisense/models/device_status.dart';
import 'package:agrisense/models/prediction.dart';
import 'package:agrisense/models/alert_item.dart';
import 'package:agrisense/models/history_response.dart';

void main() {
  group('Dart Models JSON Serialization Tests', () {
    test('SensorReading parses valid telemetry JSON accurately', () {
      final json = {
        'calibrated': {
          'temperature_c': 28.7,
          'humidity_percent': 62.1,
          'soil_moisture_estimate_percent': 42.5,
        },
        'raw': {
          'soil_ao_raw': 3100,
          'soil_do': 1,
        },
        'quality': {
          'dht_valid': true,
          'soil_valid': true,
          'all_valid': true,
          'warnings': ['Minor noise'],
        },
        'threshold_status': {
          'soil_status': 'OPTIMAL',
        },
        'timestamp': '2026-10-23T03:00:00Z',
      };

      final reading = SensorReading.fromJson(json);

      expect(reading.temperatureC, 28.7);
      expect(reading.humidityPercent, 62.1);
      expect(reading.soilMoistureEstimatePercent, 42.5);
      expect(reading.soilAoRaw, 3100);
      expect(reading.soilDo, 1);
      expect(reading.soilStatus, 'OPTIMAL');
      expect(reading.dhtValid, true);
      expect(reading.soilValid, true);
      expect(reading.allValid, true);
      expect(reading.warnings, contains('Minor noise'));
    });

    test('DeviceStatus handles online, stale, and offline states', () {
      final json = {
        'device_id': 'ESP32_AGRISENSE_01',
        'is_online': true,
        'is_stale': false,
        'seconds_since_last_seen': 2.5,
        'wifi_rssi_dbm': -72,
        'wifi_quality': 'GOOD',
        'uptime_ms': 661134,
        'last_seen_timestamp': '2026-10-23T03:00:00Z',
      };

      final status = DeviceStatus.fromJson(json);

      expect(status.deviceId, 'ESP32_AGRISENSE_01');
      expect(status.isOnline, true);
      expect(status.isStale, false);
      expect(status.secondsSinceLastSeen, 2.5);
      expect(status.wifiRssiDbm, -72);
      expect(status.wifiQuality, 'GOOD');
      expect(status.uptimeMs, 661134);
    });

    test('Prediction model parses ML results and factors', () {
      final json = {
        'available': true,
        'recommendation_type': 'ml_prediction',
        'irrigation_needed': true,
        'urgency': 'HIGH',
        'confidence': 0.985,
        'is_ml_based': true,
        'model_version': 'v1.0.0-rf-agronomic',
        'title': 'Irrigation Recommended (ML)',
        'message': 'Active moisture deficit detected.',
        'explanation': ['Soil moisture is 12.0%', 'VPD is 2.1 kPa'],
        'timestamp': '2026-10-23T03:00:00Z',
      };

      final pred = Prediction.fromJson(json);

      expect(pred.available, true);
      expect(pred.irrigationNeeded, true);
      expect(pred.urgency, 'HIGH');
      expect(pred.confidence, 0.985);
      expect(pred.isMlBased, true);
      expect(pred.explanation.length, 2);
    });

    test('AlertItem parses severity and sensor values', () {
      final json = {
        'id': 'alert_dry_1',
        'severity': 'CRITICAL',
        'title': 'Soil Moisture Depletion',
        'message': 'Moisture dropped below 25%',
        'category': 'IRRIGATION',
        'timestamp': '2026-10-23T03:00:00Z',
        'sensor_value': 18.5,
        'unit': '%',
      };

      final alert = AlertItem.fromJson(json);

      expect(alert.id, 'alert_dry_1');
      expect(alert.severity, 'CRITICAL');
      expect(alert.sensorValue, 18.5);
      expect(alert.unit, '%');
    });

    test('HistoryResponse parses records and summary', () {
      final json = {
        'summary': {
          'count': 2,
          'window_hours': 24.0,
          'temperature': {'min': 20.0, 'max': 30.0, 'avg': 25.0},
        },
        'records': [
          {
            'id': '101',
            'timestamp': '2026-10-23T01:00:00Z',
            'temperature_c': 20.0,
            'soil_moisture_estimate_percent': 35.0,
          },
          {
            'id': '102',
            'timestamp': '2026-10-23T02:00:00Z',
            'temperature_c': 30.0,
            'soil_moisture_estimate_percent': 30.0,
          },
        ],
      };

      final history = HistoryResponse.fromJson(json);

      expect(history.summary.count, 2);
      expect(history.summary.tempAvg, 25.0);
      expect(history.records.length, 2);
      expect(history.records[0].temperatureC, 20.0);
    });
  });
}
