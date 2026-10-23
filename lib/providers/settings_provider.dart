import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/api_client.dart';

class SettingsProvider with ChangeNotifier {
  final PreferencesService _prefs;
  final ApiClient _apiClient;

  bool _isTestingConnection = false;
  bool? _connectionSuccess;
  String? _connectionMessage;

  SettingsProvider(this._prefs, this._apiClient);

  String get apiBaseUrl => _prefs.apiBaseUrl;
  String get cropType => _prefs.cropType;
  String get soilType => _prefs.soilType;
  String get farmName => _prefs.farmName;
  int get pollingInterval => _prefs.pollingInterval;

  bool get isTestingConnection => _isTestingConnection;
  bool? get connectionSuccess => _connectionSuccess;
  String? get connectionMessage => _connectionMessage;

  Future<void> updateApiBaseUrl(String newUrl) async {
    await _prefs.setApiBaseUrl(newUrl);
    _apiClient.updateBaseUrl(newUrl);
    notifyListeners();
  }

  Future<void> updateCropType(String newCrop) async {
    await _prefs.setCropType(newCrop);
    notifyListeners();
  }

  Future<void> updateSoilType(String newSoil) async {
    await _prefs.setSoilType(newSoil);
    notifyListeners();
  }

  Future<void> updateFarmName(String newName) async {
    await _prefs.setFarmName(newName);
    notifyListeners();
  }

  Future<void> updatePollingInterval(int secs) async {
    await _prefs.setPollingInterval(secs);
    notifyListeners();
  }

  Future<bool> testConnection() async {
    _isTestingConnection = true;
    _connectionSuccess = null;
    _connectionMessage = 'Connecting to ${_apiClient.baseUrl}...';
    notifyListeners();

    try {
      final success = await _apiClient.checkHealth();
      _isTestingConnection = false;
      _connectionSuccess = success;
      _connectionMessage = success
          ? 'Connected successfully to AgriSense backend!'
          : 'Backend reachable, but returned degraded status.';
      notifyListeners();
      return success;
    } catch (e) {
      _isTestingConnection = false;
      _connectionSuccess = false;
      _connectionMessage = 'Failed to connect: $e';
      notifyListeners();
      return false;
    }
  }
}
