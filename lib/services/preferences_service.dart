import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

class PreferencesService {
  static const String keyApiBaseUrl = 'api_base_url';
  static const String keyCropType = 'selected_crop_type';
  static const String keySoilType = 'selected_soil_type';
  static const String keyFarmName = 'farm_name';
  static const String keyPollingInterval = 'polling_interval_seconds';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  String get apiBaseUrl => _prefs.getString(keyApiBaseUrl) ?? AppConfig.defaultBaseUrl;
  Future<void> setApiBaseUrl(String url) async => await _prefs.setString(keyApiBaseUrl, url);

  String get cropType => _prefs.getString(keyCropType) ?? 'general';
  Future<void> setCropType(String crop) async => await _prefs.setString(keyCropType, crop);

  String get soilType => _prefs.getString(keySoilType) ?? 'loam';
  Future<void> setSoilType(String soil) async => await _prefs.setString(keySoilType, soil);

  String get farmName => _prefs.getString(keyFarmName) ?? 'GreenValley Farm';
  Future<void> setFarmName(String name) async => await _prefs.setString(keyFarmName, name);

  int get pollingInterval => _prefs.getInt(keyPollingInterval) ?? AppConfig.activePollingIntervalSeconds;
  Future<void> setPollingInterval(int secs) async => await _prefs.setInt(keyPollingInterval, secs);
}
