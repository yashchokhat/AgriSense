import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/models/agronomy_models.dart';
import 'package:agrisense/features/agronomy/widgets/live_iot_metrics_bar.dart';
import 'package:agrisense/features/agronomy/widgets/crop_hero_card.dart';
import 'package:agrisense/features/agronomy/widgets/environmental_match_chart.dart';
import 'package:agrisense/features/agronomy/widgets/fertilizer_action_card.dart';
import 'package:agrisense/features/agronomy/widgets/soil_test_quick_bar.dart';
import 'package:agrisense/features/agronomy/widgets/crop_alternatives_chart.dart';

void main() {
  group('Agronomy Custom Widgets Tests', () {
    testWidgets('LiveIoTMetricsBar renders live sensor readings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveIoTMetricsBar(
              environment: {
                'temperature_c': 29.5,
                'humidity_percent': 65.0,
                'soil_moisture_estimate_percent': 82.0,
              },
              isLiveIot: true,
            ),
          ),
        ),
      );

      expect(find.text('LIVE ESP32 SENSORS'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('29.5°C'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('CropHeroCard renders best crop name and match %', (tester) async {
      const crop = CropRecommendation(
        available: true,
        recommendedCrop: 'coffee',
        displayName: 'Coffee',
        confidence: 0.88,
        suitabilityPercent: 88.0,
        description: 'Thrives in gentle highland climate.',
        farmerTip: 'Provide canopy shade trees to buffer heat.',
        idealSoil: 'Rich volcanic loam',
        alternatives: [],
        factorsAnalysis: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CropHeroCard(crop: crop),
          ),
        ),
      );

      expect(find.text('TOP ML CROP RECOMMENDATION'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('Provide canopy shade trees to buffer heat.'), findsOneWidget);
    });

    testWidgets('EnvironmentalMatchChart renders fl_chart BarChart', (tester) async {
      final factors = [
        const FactorAnalysis(
          parameter: 'Soil Moisture',
          current: '82.0 %',
          idealRange: '60 - 85 %',
          status: 'OPTIMAL',
          isFavorable: true,
          currentNum: 82.0,
          idealMin: 60.0,
          idealMax: 85.0,
        ),
        const FactorAnalysis(
          parameter: 'Temperature',
          current: '29.0 °C',
          idealRange: '20 - 30 °C',
          status: 'OPTIMAL',
          isFavorable: true,
          currentNum: 29.0,
          idealMin: 20.0,
          idealMax: 30.0,
        ),
        const FactorAnalysis(
          parameter: 'Relative Humidity',
          current: '65.0 %',
          idealRange: '60 - 80 %',
          status: 'OPTIMAL',
          isFavorable: true,
          currentNum: 65.0,
          idealMin: 60.0,
          idealMax: 80.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EnvironmentalMatchChart(factors: factors),
            ),
          ),
        ),
      );

      expect(find.text('IoT Sensor vs Crop Ideal Range'), findsOneWidget);
      expect(find.textContaining('Soil Moisture: 82.0 %'), findsOneWidget);
      expect(find.textContaining('Temperature: 29.0 °C'), findsOneWidget);
    });

    testWidgets('FertilizerActionCard renders dosage and primary nutrient', (tester) async {
      const fert = FertilizerRecommendation(
        available: true,
        recommendedFertilizer: 'Urea',
        displayName: 'Urea (46-0-0)',
        npkGrade: '46% N - 0% P - 0% K',
        primaryNutrient: 'Nitrogen (N)',
        confidencePercent: 95.0,
        recommendedDosage: '45 - 50 kg / acre',
        description: 'Fast acting N.',
        applicationGuide: 'Top-dress in split applications.',
        caution: 'Avoid placing in direct seed contact.',
        deficiencyAnalysis: {},
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FertilizerActionCard(fert: fert),
          ),
        ),
      );

      expect(find.text('RECOMMENDED FERTILIZER (ML)'), findsOneWidget);
      expect(find.text('Urea (46-0-0)'), findsOneWidget);
      expect(find.text('45 - 50 kg / acre'), findsOneWidget);
      expect(find.text('Nitrogen (N)'), findsOneWidget);
    });

    testWidgets('SoilTestQuickBar displays NPK pills and calls onEdit', (tester) async {
      bool editTapped = false;
      const soil = SoilProfile(
        nitrogen: 70.0,
        phosphorus: 35.0,
        potassium: 40.0,
        ph: 6.5,
        rainfallMm: 150.0,
        soilType: 'Loamy',
        targetCrop: 'Maize',
        isManuallyEntered: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoilTestQuickBar(
              soil: soil,
              onEdit: () => editTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Soil Test Nutrients'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);

      await tester.tap(find.text('Edit NPK'));
      expect(editTapped, true);
    });

    testWidgets('CropAlternativesChart renders alternative options', (tester) async {
      const alts = [
        CropAlternative(
          crop: 'jute',
          displayName: 'Jute',
          suitabilityPercent: 25.0,
          farmerTip: 'Requires abundant water for retting.',
        ),
        CropAlternative(
          crop: 'rice',
          displayName: 'Rice (Paddy)',
          suitabilityPercent: 20.0,
          farmerTip: 'Maintain standing water.',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CropAlternativesChart(alternatives: alts),
          ),
        ),
      );

      expect(find.text('Alternative Crop Options'), findsOneWidget);
      expect(find.text('Jute'), findsOneWidget);
      expect(find.text('25.0% Match'), findsOneWidget);
      expect(find.text('Rice (Paddy)'), findsOneWidget);
      expect(find.text('20.0% Match'), findsOneWidget);
    });
  });
}
