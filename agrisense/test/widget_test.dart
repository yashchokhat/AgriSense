import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/models/sensor_reading.dart';
import 'package:agrisense/models/prediction.dart';
import 'package:agrisense/models/device_status.dart';
import 'package:agrisense/features/dashboard/widgets/metric_card.dart';
import 'package:agrisense/features/dashboard/widgets/soil_moisture_gauge.dart';
import 'package:agrisense/features/dashboard/widgets/recommendation_card.dart';
import 'package:agrisense/features/dashboard/widgets/connectivity_banner.dart';
import 'package:agrisense/shared/widgets/loading_indicator.dart';
import 'package:agrisense/shared/widgets/error_view.dart';
import 'package:agrisense/shared/widgets/empty_state_view.dart';

void main() {
  group('AgriSense Reusable Widgets Tests', () {
    testWidgets('MetricCard displays title, value, unit and status', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              title: 'TEMPERATURE',
              value: '28.7',
              unit: '°C',
              icon: Icons.thermostat_rounded,
              accentColor: Colors.deepOrange,
              backgroundColor: Colors.orange,
              statusText: 'Optimal',
            ),
          ),
        ),
      );

      expect(find.text('TEMPERATURE'), findsOneWidget);
      expect(find.text('28.7'), findsOneWidget);
      expect(find.text('°C'), findsOneWidget);
      expect(find.text('Optimal'), findsOneWidget);
    });

    testWidgets('SoilMoistureGauge renders moisture percent and status', (WidgetTester tester) async {
      final reading = SensorReading(
        soilMoistureEstimatePercent: 45.0,
        soilAoRaw: 2900,
        soilStatus: 'OPTIMAL',
        soilDo: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoilMoistureGauge(reading: reading),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Soil Moisture Status'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('OPTIMAL'), findsOneWidget);
      expect(find.text('2900 / 4095'), findsOneWidget);
    });

    testWidgets('RecommendationCard displays ML prediction and confidence', (WidgetTester tester) async {
      final pred = Prediction(
        available: true,
        title: 'Irrigation Needed',
        message: 'Active moisture deficit detected.',
        urgency: 'HIGH',
        confidence: 0.98,
        isMlBased: true,
        irrigationNeeded: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecommendationCard(recommendation: pred),
          ),
        ),
      );

      expect(find.text('Irrigation Needed'), findsOneWidget);
      expect(find.text('Active moisture deficit detected.'), findsOneWidget);
      expect(find.text('ML MODEL'), findsOneWidget);
      expect(find.text('98.0%'), findsOneWidget);
    });

    testWidgets('ConnectivityBanner displays LIVE TELEMETRY for online device', (WidgetTester tester) async {
      final device = DeviceStatus(
        deviceId: 'ESP32_AGRISENSE_01',
        isOnline: true,
        isStale: false,
        wifiQuality: 'GOOD',
        wifiRssiDbm: -70,
        lastSeenTimestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(device: device),
          ),
        ),
      );

      expect(find.text('LIVE TELEMETRY'), findsOneWidget);
      expect(find.text('-70 dBm'), findsOneWidget);
    });

    testWidgets('ConnectivityBanner displays DATA STALE when device is stale', (WidgetTester tester) async {
      final device = DeviceStatus(
        deviceId: 'ESP32_AGRISENSE_01',
        isOnline: true,
        isStale: true,
        wifiQuality: 'FAIR',
        wifiRssiDbm: -78,
        secondsSinceLastSeen: 85,
        lastSeenTimestamp: DateTime.now().subtract(const Duration(seconds: 85)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(device: device),
          ),
        ),
      );

      expect(find.text('DATA STALE'), findsOneWidget);
      expect(find.textContaining('85s'), findsOneWidget);
    });

    testWidgets('LoadingIndicator renders message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Connecting to sensors...'),
          ),
        ),
      );

      expect(find.text('Connecting to sensors...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ErrorView renders error message and retry button', (WidgetTester tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Server unreachable',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('Server unreachable'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, true);
    });

    testWidgets('EmptyStateView renders title and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'No Data Yet',
              message: 'Check back soon.',
            ),
          ),
        ),
      );

      expect(find.text('No Data Yet'), findsOneWidget);
      expect(find.text('Check back soon.'), findsOneWidget);
    });
  });
}
