import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';

/// Application logger with environment-based configuration
class AppLogger {
  static Logger? _instance;

  /// Get singleton logger instance
  static Logger get instance {
    _instance ??= _createLogger();
    return _instance!;
  }

  /// Create logger with environment-specific configuration
  static Logger _createLogger() {
    final level = AppConstants.enableDebugLogging ? Level.debug : Level.error;

    return Logger(
      filter: _AppLogFilter(),
      printer: PrettyPrinter(
        methodCount: kDebugMode ? 2 : 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        printTime: true,
        noBoxingByDefault: !kDebugMode,
      ),
      level: level,
    );
  }

  /// Log debug message
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical message
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log network request
  static void logRequest(String method, String path, {Map<String, dynamic>? data}) {
    if (!AppConstants.enableDebugLogging) return;

    final message = '→ $method $path';
    if (data != null && data.isNotEmpty) {
      d('$message\nData: $data');
    } else {
      d(message);
    }
  }

  /// Log network response
  static void logResponse(int statusCode, String path, {dynamic data}) {
    if (!AppConstants.enableDebugLogging) return;

    final emoji = statusCode >= 200 && statusCode < 300 ? '✓' : '✗';
    final message = '$emoji $statusCode $path';

    if (statusCode >= 400) {
      w('$message\nResponse: $data');
    } else {
      d(message);
    }
  }

  /// Log network error
  static void logNetworkError(String path, dynamic error, [StackTrace? stackTrace]) {
    e('Network Error: $path', error, stackTrace);
  }

  /// Log authentication event
  static void logAuth(String event, {String? details}) {
    final message = 'Auth: $event${details != null ? " - $details" : ""}';
    i(message);
  }

  /// Log security event
  static void logSecurity(String event, {String? details}) {
    final message = 'Security: $event${details != null ? " - $details" : ""}';
    w(message);
  }

  /// Log storage operation
  static void logStorage(String operation, {bool success = true}) {
    if (!AppConstants.enableDebugLogging) return;

    final emoji = success ? '✓' : '✗';
    d('$emoji Storage: $operation');
  }

  /// Log app lifecycle event
  static void logLifecycle(String event) {
    if (!AppConstants.enableDebugLogging) return;

    i('Lifecycle: $event');
  }
}

/// Custom log filter that respects environment configuration
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode && !AppConstants.enableDebugLogging) {
      // In release mode without debug logging, only log warnings and above
      return event.level.index >= Level.warning.index;
    }

    if (!AppConstants.enableDebugLogging) {
      // If debug logging is disabled, only log info and above
      return event.level.index >= Level.info.index;
    }

    // Debug logging enabled, log everything
    return true;
  }
}
