/// API configuration constants for One-Time Secret service
class ApiConstants {
  // Prevent instantiation
  ApiConstants._();

  /// Base URL for the OTS API
  static const String baseUrl = 'https://onetimesecret.dev';

  /// API version
  static const String apiVersion = 'v2';

  /// Full API base path
  static const String apiBasePath = '$baseUrl/api/$apiVersion';

  /// API Endpoints
  static const String statusEndpoint = '/status';
  static const String shareEndpoint = '/share';
  static const String generateEndpoint = '/generate';
  static const String secretEndpoint = '/secret';

  /// Timeout configurations (in seconds)
  static const int connectTimeout = 15;
  static const int receiveTimeout = 15;

  /// Headers
  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String userAgentHeader = 'User-Agent';
  static const String userAgentValue = 'OTS-Mobile-Flutter/0.1.0';

  /// Storage keys for secure storage
  static const String apiKeyStorageKey = 'ots_api_key';
  static const String apiUsernameStorageKey = 'ots_api_username';
}
