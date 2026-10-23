import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String appName = 'AgriSense';
  static const String appVersion = '1.0.0';

  /// Production AWS EC2 endpoints
  static const String awsCloudUrl = 'http://13.233.111.26/api/v1';
  static const String awsDnsUrl =
      'http://ec2-13-233-111-26.ap-south-1.compute.amazonaws.com/api/v1';

  /// Sensible default API base URL. Defaults to the live production AWS Cloud backend.
  static String get defaultBaseUrl => awsCloudUrl;

  // Polling interval presets in seconds
  static const int activePollingIntervalSeconds = 3;
  static const int backgroundPollingIntervalSeconds = 30;

  // Network timeouts in milliseconds
  static const int connectTimeoutMs = 8000;
  static const int receiveTimeoutMs = 8000;
}
