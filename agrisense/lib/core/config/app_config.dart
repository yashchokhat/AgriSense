import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String appName = 'AgriSense';
  static const String appVersion = '1.0.0';

  /// Production AWS EC2 endpoint
  static const String awsCloudUrl = 'http://13.233.111.26/api/v1';

  /// Determines the sensible default API base URL based on platform.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5001/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // Standard Android emulator loopback alias to host machine
        return 'http://10.0.2.2:5001/api/v1';
      }
    } catch (_) {
      // Fallback if Platform check fails
    }
    return 'http://127.0.0.1:5001/api/v1';
  }

  // Polling interval presets in seconds
  static const int activePollingIntervalSeconds = 3;
  static const int backgroundPollingIntervalSeconds = 30;

  // Network timeouts in milliseconds
  static const int connectTimeoutMs = 8000;
  static const int receiveTimeoutMs = 8000;
}
