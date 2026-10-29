import 'package:flutter/material.dart';
import '../models/agronomy_models.dart';
import '../services/api_client.dart';
import '../services/preferences_service.dart';
import '../core/errors/app_exception.dart';

class AgronomyProvider with ChangeNotifier {
  final ApiClient _apiClient;
  final PreferencesService _prefs;

  SoilProfile _soilProfile;
  AgronomyAdvisory? _advisory;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Real-time Weather & Sensor Simulation State
  bool _isSimulationMode = false;
  double _simTemp = 26.0;
  double _simHumidity = 60.0;
  double _simMoisture = 50.0;
  String _selectedCategory = 'All';

  AgronomyProvider(this._apiClient, this._prefs)
      : _soilProfile = SoilProfile(
          nitrogen: _prefs.soilNitrogen,
          phosphorus: _prefs.soilPhosphorus,
          potassium: _prefs.soilPotassium,
          ph: _prefs.soilPh,
          rainfallMm: _prefs.soilRainfall,
          soilType: _prefs.soilType,
          targetCrop: _prefs.cropType,
          isManuallyEntered: true,
        ) {
    fetchAdvisory();
  }

  SoilProfile get soilProfile => _soilProfile;
  AgronomyAdvisory? get advisory => _advisory;
  CropRecommendation? get cropRecommendation => _advisory?.cropRecommendation;
  FertilizerRecommendation? get fertilizerRecommendation => _advisory?.fertilizerRecommendation;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get isSimulationMode => _isSimulationMode;
  double get simTemp => _simTemp;
  double get simHumidity => _simHumidity;
  double get simMoisture => _simMoisture;
  String get selectedCategory => _selectedCategory;

  void setSelectedCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void toggleSimulationMode(bool enabled) {
    _isSimulationMode = enabled;
    if (!enabled) {
      fetchAdvisory();
    } else {
      simulateConditions();
    }
  }

  Future<void> simulateConditions({double? temp, double? hum, double? moisture}) async {
    if (temp != null) _simTemp = temp;
    if (hum != null) _simHumidity = hum;
    if (moisture != null) _simMoisture = moisture;

    try {
      final overrides = {
        'temperature_c': _simTemp,
        'humidity_percent': _simHumidity,
        'soil_moisture_estimate_percent': _simMoisture,
      };
      _advisory = await _apiClient.runCustomAgronomyAdvisory(overrides);
      _errorMessage = null;
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Simulation failed: $e';
      notifyListeners();
    }
  }

  Future<void> applyWeatherPreset(String presetKey) async {
    switch (presetKey) {
      case 'cool_winter':
        await simulateConditions(temp: 16.0, hum: 65.0, moisture: 55.0);
        break;
      case 'hot_summer':
        await simulateConditions(temp: 34.0, hum: 42.0, moisture: 25.0);
        break;
      case 'monsoon_rain':
        await simulateConditions(temp: 27.0, hum: 85.0, moisture: 85.0);
        break;
      case 'spring_mild':
      default:
        await simulateConditions(temp: 23.0, hum: 58.0, moisture: 50.0);
        break;
    }
  }

  Future<void> fetchAdvisory({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _advisory = await _apiClient.getAgronomyAdvisory();
      if (_advisory != null) {
        _soilProfile = _advisory!.soilProfile;
      }
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load agronomy advisory: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSoilProfile(SoilProfile newProfile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Save locally in Preferences
      await _prefs.setSoilNitrogen(newProfile.nitrogen);
      await _prefs.setSoilPhosphorus(newProfile.phosphorus);
      await _prefs.setSoilPotassium(newProfile.potassium);
      await _prefs.setSoilPh(newProfile.ph);
      await _prefs.setSoilRainfall(newProfile.rainfallMm);
      await _prefs.setSoilType(newProfile.soilType);
      await _prefs.setCropType(newProfile.targetCrop);

      _soilProfile = newProfile;

      // 2. Sync with backend API
      final updated = await _apiClient.updateSoilProfile(newProfile);
      _soilProfile = updated;

      // 3. Immediately re-run agronomy advisory with new parameters
      _advisory = await _apiClient.getAgronomyAdvisory();
      _isSaving = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update soil profile: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> applyPreset(String presetKey) async {
    SoilProfile preset;
    switch (presetKey) {
      case 'nitrogen_low':
        preset = _soilProfile.copyWith(
          nitrogen: 15.0,
          phosphorus: 45.0,
          potassium: 40.0,
          ph: 6.6,
          soilType: 'Loamy',
          isManuallyEntered: true,
        );
        break;
      case 'phosphorus_low':
        preset = _soilProfile.copyWith(
          nitrogen: 60.0,
          phosphorus: 12.0,
          potassium: 45.0,
          ph: 6.2,
          soilType: 'Loamy',
          isManuallyEntered: true,
        );
        break;
      case 'potassium_low':
        preset = _soilProfile.copyWith(
          nitrogen: 45.0,
          phosphorus: 35.0,
          potassium: 10.0,
          ph: 7.0,
          soilType: 'Red',
          isManuallyEntered: true,
        );
        break;
      case 'acidic_soil':
        preset = _soilProfile.copyWith(
          nitrogen: 40.0,
          phosphorus: 30.0,
          potassium: 35.0,
          ph: 5.2,
          soilType: 'Clayey',
          isManuallyEntered: true,
        );
        break;
      case 'black_cotton':
        preset = _soilProfile.copyWith(
          nitrogen: 70.0,
          phosphorus: 45.0,
          potassium: 50.0,
          ph: 7.8,
          soilType: 'Black',
          isManuallyEntered: true,
        );
        break;
      case 'sandy_coastal':
        preset = _soilProfile.copyWith(
          nitrogen: 25.0,
          phosphorus: 20.0,
          potassium: 25.0,
          ph: 6.8,
          soilType: 'Sandy',
          isManuallyEntered: true,
        );
        break;
      case 'balanced_loam':
      default:
        preset = _soilProfile.copyWith(
          nitrogen: 50.0,
          phosphorus: 40.0,
          potassium: 40.0,
          ph: 6.5,
          soilType: 'Loamy',
          isManuallyEntered: true,
        );
        break;
    }
    await updateSoilProfile(preset);
  }
}
