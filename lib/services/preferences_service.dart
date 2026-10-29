import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

class PreferencesService {
  static const String keyApiBaseUrl = 'api_base_url';
  static const String keyCropType = 'selected_crop_type';
  static const String keySoilType = 'selected_soil_type';
  static const String keyFarmName = 'farm_name';
  static const String keyPollingInterval = 'polling_interval_seconds';
  static const String keySoilNitrogen = 'soil_nitrogen';
  static const String keySoilPhosphorus = 'soil_phosphorus';
  static const String keySoilPotassium = 'soil_potassium';
  static const String keySoilPh = 'soil_ph';
  static const String keySoilRainfall = 'soil_rainfall';

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

  double get soilNitrogen => _prefs.getDouble(keySoilNitrogen) ?? 50.0;
  Future<void> setSoilNitrogen(double n) async => await _prefs.setDouble(keySoilNitrogen, n);

  double get soilPhosphorus => _prefs.getDouble(keySoilPhosphorus) ?? 40.0;
  Future<void> setSoilPhosphorus(double p) async => await _prefs.setDouble(keySoilPhosphorus, p);

  double get soilPotassium => _prefs.getDouble(keySoilPotassium) ?? 40.0;
  Future<void> setSoilPotassium(double k) async => await _prefs.setDouble(keySoilPotassium, k);

  double get soilPh => _prefs.getDouble(keySoilPh) ?? 6.5;
  Future<void> setSoilPh(double ph) async => await _prefs.setDouble(keySoilPh, ph);

  double get soilRainfall => _prefs.getDouble(keySoilRainfall) ?? 100.0;
  Future<void> setSoilRainfall(double rain) async => await _prefs.setDouble(keySoilRainfall, rain);
}
