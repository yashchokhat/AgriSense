import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/dashboard_data.dart';
import '../models/history_response.dart';
import '../core/errors/app_exception.dart';
import 'settings_provider.dart';

class SensorProvider with ChangeNotifier {
  final ApiClient _apiClient;
  final SettingsProvider _settings;

  DashboardData? _dashboardData;
  HistoryResponse? _historyData;
  double _selectedHistoryHours = 24.0;

  bool _isLoadingDashboard = false;
  bool _isLoadingHistory = false;
  bool _isRunningInference = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;

  Timer? _pollingTimer;
  bool _isPollingActive = true;

  SensorProvider(this._apiClient, this._settings) {
    // Initial fetch and start active polling
    fetchDashboard(isInitial: true);
    fetchHistory(hours: _selectedHistoryHours);
    startPolling();
  }

  DashboardData? get dashboard => _dashboardData;
  HistoryResponse? get history => _historyData;
  double get selectedHistoryHours => _selectedHistoryHours;

  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isRunningInference => _isRunningInference;
  String? get errorMessage => _errorMessage;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get isPollingActive => _isPollingActive;

  void startPolling() {
    _pollingTimer?.cancel();
    final interval = Duration(seconds: _settings.pollingInterval);
    _pollingTimer = Timer.periodic(interval, (_) {
      if (_isPollingActive && !_isLoadingDashboard) {
        fetchDashboard(silent: true);
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void setPollingActive(bool active) {
    _isPollingActive = active;
  }

  Future<void> fetchDashboard({bool isInitial = false, bool silent = false}) async {
    if (isInitial) {
      _isLoadingDashboard = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final data = await _apiClient.getDashboard(
        cropType: _settings.cropType,
        soilType: _settings.soilType,
      );
      _dashboardData = data;
      _errorMessage = null;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      if (!silent || _dashboardData == null) {
        _errorMessage = e is AppException ? e.message : 'Failed to fetch sensor data: $e';
      }
    } finally {
      if (isInitial) {
        _isLoadingDashboard = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchHistory({double? hours, bool silent = false}) async {
    if (hours != null) {
      _selectedHistoryHours = hours;
    }

    if (!silent) {
      _isLoadingHistory = true;
      notifyListeners();
    }

    try {
      final res = await _apiClient.getSensorHistory(
        hours: _selectedHistoryHours,
        limit: 120,
      );
      _historyData = res;
    } catch (e) {
      // Historical fetch failure is non-fatal; preserve existing history if any
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> runImmediateInference({bool forceRuleBased = false}) async {
    _isRunningInference = true;
    notifyListeners();

    try {
      final pred = await _apiClient.runPrediction(
        cropType: _settings.cropType,
        soilType: _settings.soilType,
        forceRuleBased: forceRuleBased,
      );

      // Update recommendation in dashboard data
      if (_dashboardData != null) {
        _dashboardData = DashboardData(
          device: _dashboardData!.device,
          telemetry: _dashboardData!.telemetry,
          recommendation: pred,
          alerts: _dashboardData!.alerts,
          totalAlertsCount: _dashboardData!.totalAlertsCount,
          criticalAlertsCount: _dashboardData!.criticalAlertsCount,
          trends24h: _dashboardData!.trends24h,
        );
      }
    } catch (e) {
      _errorMessage = e is AppException ? e.message : 'Inference failed: $e';
    } finally {
      _isRunningInference = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchDashboard(isInitial: false, silent: false),
      fetchHistory(hours: _selectedHistoryHours, silent: false),
    ]);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
