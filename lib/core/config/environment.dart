import 'package:flutter/foundation.dart';

/// Environment configuration for the application
enum Environment {
  development,
  staging,
  production,
}

/// Environment configuration class
class EnvironmentConfig {
  final Environment environment;
  final String baseUrl;
  final bool enableCertificatePinning;
  final bool enableDebugLogging;
  final bool enableRASP;
  final int connectionTimeout;
  final int receiveTimeout;

  const EnvironmentConfig({
    required this.environment,
    required this.baseUrl,
    required this.enableCertificatePinning,
    required this.enableDebugLogging,
    required this.enableRASP,
    required this.connectionTimeout,
    required this.receiveTimeout,
  });

  /// Development environment configuration
  static const development = EnvironmentConfig(
    environment: Environment.development,
    baseUrl: 'https://onetimesecret.com',
    enableCertificatePinning: false, // Disabled for easier development
    enableDebugLogging: true,
    enableRASP: false, // Disabled for development
    connectionTimeout: 30000,
    receiveTimeout: 30000,
  );

  /// Staging environment configuration
  static const staging = EnvironmentConfig(
    environment: Environment.staging,
    baseUrl: 'https://staging.onetimesecret.com',
    enableCertificatePinning: true,
    enableDebugLogging: true,
    enableRASP: true,
    connectionTimeout: 30000,
    receiveTimeout: 30000,
  );

  /// Production environment configuration
  static const production = EnvironmentConfig(
    environment: Environment.production,
    baseUrl: 'https://onetimesecret.com',
    enableCertificatePinning: true,
    enableDebugLogging: false,
    enableRASP: true,
    connectionTimeout: 30000,
    receiveTimeout: 30000,
  );

  /// Custom environment configuration (for self-hosted instances)
  factory EnvironmentConfig.custom({
    required String baseUrl,
    bool enableCertificatePinning = true,
    bool enableDebugLogging = false,
    bool enableRASP = true,
    int connectionTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    return EnvironmentConfig(
      environment: Environment.development,
      baseUrl: baseUrl,
      enableCertificatePinning: enableCertificatePinning,
      enableDebugLogging: enableDebugLogging,
      enableRASP: enableRASP,
      connectionTimeout: connectionTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  /// Get current environment configuration
  static EnvironmentConfig get current {
    // Can be overridden with --dart-define
    const envString = String.fromEnvironment('ENV', defaultValue: 'production');

    switch (envString.toLowerCase()) {
      case 'development':
      case 'dev':
        return development;
      case 'staging':
      case 'stage':
        return staging;
      case 'production':
      case 'prod':
        return production;
      default:
        // Default to production for safety
        if (kDebugMode) {
          return development;
        }
        return production;
    }
  }

  /// Check if running in development mode
  bool get isDevelopment => environment == Environment.development;

  /// Check if running in staging mode
  bool get isStaging => environment == Environment.staging;

  /// Check if running in production mode
  bool get isProduction => environment == Environment.production;

  /// Get environment name as string
  String get environmentName {
    switch (environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  @override
  String toString() {
    return 'EnvironmentConfig('
        'environment: $environmentName, '
        'baseUrl: $baseUrl, '
        'enableCertificatePinning: $enableCertificatePinning, '
        'enableDebugLogging: $enableDebugLogging, '
        'enableRASP: $enableRASP'
        ')';
  }
}
