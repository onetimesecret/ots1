/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'OneTimeSecret';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Secure, privacy-first secret sharing application';

  // API Configuration
  static const String baseUrl = 'https://onetimesecret.com';
  static const String apiVersion = 'v2';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';

  // API Endpoints
  static const String shareEndpoint = '/share';
  static const String secretEndpoint = '/secret';
  static const String statusEndpoint = '/status';
  static const String privateEndpoint = '/private';
  static const String localesEndpoint = '/supported-locales';
  static const String versionEndpoint = '/version';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Retry Configuration
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // 1 second

  // Storage Keys
  static const String storageKeyApiKey = 'api_key';
  static const String storageKeyUsername = 'username';
  static const String storageKeyAuthToken = 'auth_token';
  static const String storageKeyRecentSecrets = 'recent_secrets';
  static const String storageKeySettings = 'settings';

  // Certificate Pinning
  static const String certificateFingerprint =
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
  static const List<String> allowedSHA256Fingerprints = [
    // Add your certificate fingerprints here
    // Example: 'sha256/...'
  ];

  // Rate Limiting
  static const int maxSecretsPerMinute = 10;
  static const int maxSecretsPerHour = 100;

  // Secret Configuration
  static const int maxSecretLength = 1000000; // 1MB
  static const int maxPassphraseLength = 256;
  static const int defaultTtl = 604800; // 7 days in seconds
  static const int minTtl = 300; // 5 minutes
  static const int maxTtl = 2592000; // 30 days

  // UI Configuration
  static const double maxContentWidth = 600.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;

  // Security
  static const int minPasswordLength = 8;
  static const bool enableCertificatePinning = true;
  static const bool enableObfuscation = true;
}
