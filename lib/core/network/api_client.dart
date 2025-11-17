import 'package:dio/dio.dart';

import '../../shared/services/secure_storage_service.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'http_client_factory.dart';

/// Main API client for communicating with Onetimesecret API
class ApiClient {
  final HttpClientFactory httpClientFactory;
  final SecureStorageService secureStorage;
  late final Dio _dio;

  ApiClient({
    required this.httpClientFactory,
    required this.secureStorage,
  }) {
    _dio = httpClientFactory.createDioClient();
  }

  /// Add authentication token to request headers
  Future<void> _addAuthHeaders(Map<String, dynamic> headers) async {
    final apiKey = await secureStorage.read(
      key: AppConstants.apiKeyStorageKey,
    );

    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Basic $apiKey';
    }
  }

  /// Make a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      await _addAuthHeaders(headers);

      final mergedOptions = (options ?? Options()).copyWith(
        headers: {...?options?.headers, ...headers},
      );

      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Make a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      await _addAuthHeaders(headers);

      final mergedOptions = (options ?? Options()).copyWith(
        headers: {...?options?.headers, ...headers},
      );

      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Make a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      await _addAuthHeaders(headers);

      final mergedOptions = (options ?? Options()).copyWith(
        headers: {...?options?.headers, ...headers},
      );

      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Make a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      await _addAuthHeaders(headers);

      final mergedOptions = (options ?? Options()).copyWith(
        headers: {...?options?.headers, ...headers},
      );

      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Handle Dio exceptions and convert to app exceptions
  AppException _handleDioException(DioException error) {
    if (error.error is AppException) {
      return error.error as AppException;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timeout',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Request failed';

        if (statusCode == 401 || statusCode == 403) {
          return AuthException(
            message: message,
            code: 'UNAUTHORIZED',
            originalError: error,
          );
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          code: 'API_ERROR',
          originalError: error,
        );

      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Request cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection',
          code: 'NO_CONNECTION',
        );

      default:
        return NetworkException(
          message: error.message ?? 'Unknown network error',
          code: 'UNKNOWN',
          originalError: error,
        );
    }
  }
}
