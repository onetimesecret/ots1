import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../security/secure_storage_service.dart';

/// Custom HTTP client with built-in error handling, authentication,
/// and security features for OTS API communication
class OTSHttpClient {
  final http.Client client;
  final SecureStorageService secureStorage;

  OTSHttpClient({
    required this.client,
    required this.secureStorage,
  });

  /// Builds headers for API requests including authentication if available
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': ApiConstants.contentTypeJson,
      ApiConstants.userAgentHeader: ApiConstants.userAgentValue,
    };

    // Add API authentication if credentials are stored
    final apiKey = await secureStorage.read(
      key: ApiConstants.apiKeyStorageKey,
    );
    final username = await secureStorage.read(
      key: ApiConstants.apiUsernameStorageKey,
    );

    if (apiKey != null && username != null) {
      final credentials = base64Encode(utf8.encode('$username:$apiKey'));
      headers[ApiConstants.authorizationHeader] = 'Basic $credentials';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handles HTTP response and throws appropriate exceptions
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success
    }

    String message = 'Request failed';
    try {
      final body = json.decode(response.body);
      message = body['message'] ?? body['error'] ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }

    switch (response.statusCode) {
      case 400:
        throw ValidationException(message: message);
      case 401:
      case 403:
        throw AuthException(
          message: message,
          statusCode: response.statusCode,
        );
      case 404:
        throw NotFoundException(message: message);
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException(
          message: 'Server error: $message',
          statusCode: response.statusCode,
        );
      default:
        throw ServerException(
          message: message,
          statusCode: response.statusCode,
        );
    }
  }

  /// Performs a GET request
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.apiBasePath}$path').replace(
        queryParameters: queryParams,
      );

      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      final response = await client
          .get(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: ApiConstants.connectTimeout));

      _handleResponse(response);
      return response;
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'Request timeout',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network error: ${e.message}',
      );
    }
  }

  /// Performs a POST request
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.apiBasePath}$path');
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      final response = await client
          .post(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: ApiConstants.connectTimeout));

      _handleResponse(response);
      return response;
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'Request timeout',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network error: ${e.message}',
      );
    }
  }

  /// Performs a PUT request
  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.apiBasePath}$path');
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      final response = await client
          .put(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: ApiConstants.connectTimeout));

      _handleResponse(response);
      return response;
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'Request timeout',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network error: ${e.message}',
      );
    }
  }

  /// Performs a DELETE request
  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.apiBasePath}$path');
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      final response = await client
          .delete(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: ApiConstants.connectTimeout));

      _handleResponse(response);
      return response;
    } on SocketException {
      throw const NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'Request timeout',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network error: ${e.message}',
      );
    }
  }

  /// Closes the underlying HTTP client
  void close() {
    client.close();
  }
}
