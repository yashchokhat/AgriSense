import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/models/agronomy_models.dart';

void main() {
  group('Agronomy Models Tests', () {
    test('SoilProfile parses default values and converts to JSON', () {
      final defaults = SoilProfile.defaults();
      expect(defaults.nitrogen, 50.0);
      expect(defaults.phosphorus, 40.0);
      expect(defaults.potassium, 40.0);
      expect(defaults.ph, 6.5);
      expect(defaults.soilType, 'Loamy');
      expect(defaults.isManuallyEntered, false);

      final json = defaults.toJson();
      expect(json['nitrogen'], 50.0);
      expect(json['ph'], 6.5);

      final parsed = SoilProfile.fromJson(json);
      expect(parsed.nitrogen, 50.0);
      expect(parsed.targetCrop, 'Maize');
    });

    test('CropRecommendation parses Kaggle prediction JSON', () {
      final json = {
        'available': true,
        'recommended_crop': 'rice',
        'display_name': 'Rice (Paddy)',
        'confidence': 0.985,
        'suitability_percent': 98.5,
        'description': 'High water and moisture requirement.',
        'farmer_tip': 'Maintain 2-5 cm standing water during tillering.',
        'ideal_soil': 'Clayey / Loamy',
        'alternatives': [
          {
            'crop': 'jute',
            'display_name': 'Jute',
            'suitability_percent': 78.0,
            'farmer_tip': 'Requires abundant water.',
          }
        ],
        'factors_analysis': [
          {
            'parameter': 'Temperature',
            'current': '25.0 °C',
            'ideal_range': '20 - 35 °C',
            'status': 'OPTIMAL',
            'is_favorable': true,
          }
        ],
      };

      final rec = CropRecommendation.fromJson(json);
      expect(rec.available, true);
      expect(rec.recommendedCrop, 'rice');
      expect(rec.displayName, 'Rice (Paddy)');
      expect(rec.suitabilityPercent, 98.5);
      expect(rec.alternatives.length, 1);
      expect(rec.alternatives.first.displayName, 'Jute');
      expect(rec.factorsAnalysis.length, 1);
      expect(rec.factorsAnalysis.first.isFavorable, true);
    });

    test('FertilizerRecommendation parses Kaggle prediction JSON', () {
      final json = {
        'available': true,
        'recommended_fertilizer': 'Urea',
        'display_name': 'Urea (46-0-0)',
        'npk_grade': '46% N - 0% P - 0% K',
        'primary_nutrient': 'Nitrogen (N)',
        'confidence_percent': 100.0,
        'recommended_dosage': '45 - 50 kg / acre in split doses',
        'description': 'High concentration Nitrogen fertilizer.',
        'application_guide': 'Top-dress when soil is damp.',
        'caution': 'Do not place in contact with seeds.',
        'deficiency_analysis': {
          'nitrogen_status': 'LOW',
          'summary': 'Nitrogen is low.',
        },
      };

      final fert = FertilizerRecommendation.fromJson(json);
      expect(fert.available, true);
      expect(fert.recommendedFertilizer, 'Urea');
      expect(fert.displayName, 'Urea (46-0-0)');
      expect(fert.confidencePercent, 100.0);
      expect(fert.deficiencyAnalysis['nitrogen_status'], 'LOW');
    });

    test('AgronomyAdvisory parses full composite payload', () {
      final json = {
        'timestamp': '2026-10-24T00:00:00Z',
        'telemetry_source': {
          'is_live_iot': true,
          'temperature_source': 'ESP32_DHT11',
        },
        'environment': {
          'temperature_c': 28.0,
          'humidity_percent': 62.0,
          'soil_moisture_estimate_percent': 38.0,
        },
        'soil_profile': {
          'nitrogen': 45.0,
          'phosphorus': 38.0,
          'potassium': 42.0,
          'ph': 6.8,
          'rainfall_mm': 110.0,
          'soil_type': 'Loamy',
          'target_crop': 'Maize',
          'is_manually_entered': true,
        },
        'crop_recommendation': {
          'available': true,
          'recommended_crop': 'maize',
          'display_name': 'Maize (Corn)',
          'confidence': 0.95,
          'suitability_percent': 95.0,
        },
        'fertilizer_recommendation': {
          'available': true,
          'recommended_fertilizer': 'DAP',
          'display_name': 'DAP (18-46-0)',
          'confidence_percent': 92.0,
        },
      };

      final advisory = AgronomyAdvisory.fromJson(json);
      expect(advisory.telemetrySource['is_live_iot'], true);
      expect(advisory.environment['temperature_c'], 28.0);
      expect(advisory.soilProfile.isManuallyEntered, true);
      expect(advisory.cropRecommendation.recommendedCrop, 'maize');
      expect(advisory.fertilizerRecommendation.recommendedFertilizer, 'DAP');
    });
  });
}
