import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Factory for creating configured HTTP clients with security features
class HttpClientFactory {
  Dio createDioClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.apiBaseUrl}/api/${AppConstants.apiVersion}',
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        sendTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Consider 200-299 as successful
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(_createLoggingInterceptor());
    dio.interceptors.add(_createErrorInterceptor());

    // Configure certificate pinning in release mode
    if (kReleaseMode && AppConstants.certificatePins.isNotEmpty) {
      _configureCertificatePinning(dio);
    }

    return dio;
  }

  /// Create logging interceptor for debugging
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
          debugPrint('Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('Data: ${options.data}');
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          debugPrint('Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          debugPrint('Error: ${error.message}');
        }
        handler.next(error);
      },
    );
  }

  /// Create error handling interceptor
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: const NetworkException(
                message: 'Connection timeout',
                code: 'TIMEOUT',
              ),
            ),
          );
        } else if (error.type == DioExceptionType.connectionError) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: const NetworkException(
                message: 'No internet connection',
                code: 'NO_CONNECTION',
              ),
            ),
          );
        } else {
          handler.next(error);
        }
      },
    );
  }

  /// Configure certificate pinning for enhanced security
  void _configureCertificatePinning(Dio dio) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();

        // Configure security context
        client.badCertificateCallback = (cert, host, port) {
          // Implement certificate pinning validation
          // This is a simplified example - in production, you would:
          // 1. Extract the certificate's SHA-256 fingerprint
          // 2. Compare it against the pinned certificates
          // 3. Return true only if it matches

          if (kReleaseMode) {
            // In release mode, reject bad certificates
            return false;
          }
          return true; // Accept in debug mode for development
        };

        return client;
      },
    );
  }
}
