import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../models/dashboard_data.dart';
import '../models/sensor_reading.dart';
import '../models/prediction.dart';
import '../models/alert_item.dart';
import '../models/history_response.dart';
import '../models/agronomy_models.dart';

class ApiClient {
  late Dio _dio;
  String _baseUrl;

  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? AppConfig.defaultBaseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl.endsWith('/') ? newUrl.substring(0, newUrl.length - 1) : newUrl;
    _dio.options.baseUrl = _baseUrl;
  }

  String get baseUrl => _baseUrl;

  /// Check connectivity and backend health
  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get('/health');
      if (res.statusCode == 200 || res.statusCode == 207) {
        return res.data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Consolidated dashboard summary
  Future<DashboardData> getDashboard({String cropType = 'general', String soilType = 'loam'}) async {
    try {
      final res = await _dio.get(
        '/dashboard',
        queryParameters: {'crop_type': cropType, 'soil_type': soilType},
      );
      _validateResponse(res);
      return DashboardData.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Latest raw/calibrated sensor reading
  Future<SensorReading> getLatestSensorReading() async {
    try {
      final res = await _dio.get('/sensors/latest');
      _validateResponse(res);
      return SensorReading.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Historical sensor data
  Future<HistoryResponse> getSensorHistory({double hours = 24.0, int limit = 100}) async {
    try {
      final res = await _dio.get(
        '/sensors/history',
        queryParameters: {'hours': hours, 'limit': limit},
      );
      _validateResponse(res);
      return HistoryResponse.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Latest ML prediction / recommendation
  Future<Prediction> getLatestPrediction({String cropType = 'general', String soilType = 'loam'}) async {
    try {
      final res = await _dio.get(
        '/predictions/latest',
        queryParameters: {'crop_type': cropType, 'soil_type': soilType},
      );
      _validateResponse(res);
      return Prediction.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Run an immediate prediction inference
  Future<Prediction> runPrediction({
    String cropType = 'general',
    String soilType = 'loam',
    bool forceRuleBased = false,
  }) async {
    try {
      final res = await _dio.post(
        '/predictions/run',
        data: {
          'crop_type': cropType,
          'soil_type': soilType,
          'force_rule_based': forceRuleBased,
        },
      );
      _validateResponse(res);
      return Prediction.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Active Alerts
  Future<List<AlertItem>> getAlerts() async {
    try {
      final res = await _dio.get('/alerts');
      _validateResponse(res);
      final rawList = res.data['data']['alerts'] as List<dynamic>? ?? [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((a) => AlertItem.fromJson(a))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// System Configuration & Options
  Future<Map<String, dynamic>> getConfig() async {
    try {
      final res = await _dio.get('/config');
      _validateResponse(res);
      return res.data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update thresholds on backend
  Future<void> updateConfig(Map<String, dynamic> thresholds) async {
    try {
      final res = await _dio.post('/config', data: {'thresholds': thresholds});
      _validateResponse(res);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Unified Smart Agronomy Advisory (Kaggle ML Models for Crop & Fertilizer + Soil NPK/pH)
  Future<AgronomyAdvisory> getAgronomyAdvisory() async {
    try {
      final res = await _dio.get('/recommendations/agronomy');
      _validateResponse(res);
      return AgronomyAdvisory.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Run custom agronomy advisory with overrides
  Future<AgronomyAdvisory> runCustomAgronomyAdvisory(Map<String, dynamic> overrides) async {
    try {
      final res = await _dio.post('/recommendations/agronomy', data: overrides);
      _validateResponse(res);
      return AgronomyAdvisory.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get active Soil Test Profile
  Future<SoilProfile> getSoilProfile() async {
    try {
      final res = await _dio.get('/recommendations/soil-profile');
      _validateResponse(res);
      return SoilProfile.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update active Soil Test Profile
  Future<SoilProfile> updateSoilProfile(SoilProfile profile) async {
    try {
      final res = await _dio.post('/recommendations/soil-profile', data: profile.toJson());
      _validateResponse(res);
      return SoilProfile.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Predict Crop using Kaggle ML model
  Future<CropRecommendation> predictCrop(Map<String, dynamic> params) async {
    try {
      final res = await _dio.post('/recommendations/crop', data: params);
      _validateResponse(res);
      return CropRecommendation.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Predict Fertilizer using Kaggle ML model
  Future<FertilizerRecommendation> predictFertilizer(Map<String, dynamic> params) async {
    try {
      final res = await _dio.post('/recommendations/fertilizer', data: params);
      _validateResponse(res);
      return FertilizerRecommendation.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  void _validateResponse(Response res) {
    if (res.data is Map<String, dynamic>) {
      final success = res.data['success'] == true;
      if (!success) {
        final err = res.data['error'] as Map<String, dynamic>?;
        throw ServerException(
          err?['message'] ?? 'API reported unsuccessful status',
          statusCode: res.statusCode ?? 500,
          code: err?['code']?.toString(),
          details: err?['details'],
        );
      }
    }
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException('Connection timed out. Check that Flask API is running.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Cannot reach API server at $_baseUrl. Ensure backend is running and reachable on this host/port.',
      );
    }
    if (e.response != null) {
      final status = e.response!.statusCode ?? 500;
      final data = e.response!.data;
      String msg = 'Server returned HTTP $status';
      String? code;
      dynamic details;

      if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
        msg = data['error']['message'] ?? msg;
        code = data['error']['code']?.toString();
        details = data['error']['details'];
      }
      return ServerException(msg, statusCode: status, code: code, details: details);
    }
    return NetworkException(e.message ?? 'Network error occurred');
  }
}
