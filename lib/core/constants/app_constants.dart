/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Onetimesecret';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiBaseUrl = 'https://onetimesecret.com';
  static const String apiVersion = 'v2';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Security
  static const String secureStorageKeyPrefix = 'ots_';
  static const String authTokenKey = '${secureStorageKeyPrefix}auth_token';
  static const String apiKeyStorageKey = '${secureStorageKeyPrefix}api_key';

  // Certificate Pinning (SHA-256 fingerprints)
  // These should be updated with actual certificate fingerprints
  static const List<String> certificatePins = [
    // Add actual certificate pins here
    // Example: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
  ];
}
