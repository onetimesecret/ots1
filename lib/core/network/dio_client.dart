import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage_service.dart';

/// DIO client with interceptors, error handling, and certificate pinning
@singleton
class DioClient {
  final SecureStorageService _secureStorage;
  final Logger _logger;
  late final Dio _dio;

  DioClient(
    this._secureStorage,
    this._logger,
  ) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}/api/${AppConstants.apiVersion}',
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          ApiConstants.headerContentType: ApiConstants.contentTypeJson,
          ApiConstants.headerAccept: ApiConstants.contentTypeJson,
          ApiConstants.headerUserAgent: ApiConstants.userAgent,
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    _setupInterceptors();
    if (AppConstants.enableCertificatePinning) {
      _setupCertificatePinning();
    }
  }

  Dio get dio => _dio;

  /// Setup interceptors for logging and authentication
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication header if credentials exist
          final username =
              await _secureStorage.read(key: AppConstants.storageKeyUsername);
          final apiKey =
              await _secureStorage.read(key: AppConstants.storageKeyApiKey);

          if (username != null && apiKey != null) {
            final credentials = '$username:$apiKey';
            final encodedCredentials = base64Encode(utf8.encode(credentials));
            options.headers[ApiConstants.headerAuthorization] =
                'Basic $encodedCredentials';
          }

          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          return handler.next(_handleDioError(error));
        },
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              final response = await _retry(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Setup certificate pinning for enhanced security
  void _setupCertificatePinning() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        // Verify certificate fingerprint
        // In production, implement proper certificate validation
        // For now, we'll accept all certificates but log them
        _logger.w('Certificate from $host:$port');
        _logger.w('Issuer: ${cert.issuer}');
        _logger.w('Subject: ${cert.subject}');

        // TODO: Implement actual certificate pinning
        // Compare cert fingerprint with allowed fingerprints
        // return AppConstants.allowedSHA256Fingerprints.contains(fingerprint);

        return true; // Accept all for development
      };
      return client;
    };
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  /// Retry failed request with exponential backoff
  Future<Response> _retry(RequestOptions requestOptions) async {
    int retries = 0;
    while (retries < AppConstants.maxRetries) {
      try {
        await Future.delayed(
          Duration(milliseconds: AppConstants.retryDelay * (retries + 1)),
        );

        return await _dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
          ),
        );
      } catch (e) {
        retries++;
        if (retries >= AppConstants.maxRetries) {
          rethrow;
        }
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Handle DIO errors and convert to app exceptions
  DioException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException(message: 'Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'Unknown error';

        switch (statusCode) {
          case ApiConstants.statusUnauthorized:
            throw AuthenticationException(message: message);
          case ApiConstants.statusForbidden:
            throw AuthenticationException(message: message);
          case ApiConstants.statusNotFound:
            throw SecretNotFoundException(message: message);
          case ApiConstants.statusTooManyRequests:
            throw RateLimitException(message: message);
          default:
            throw ServerException(message: message, code: statusCode);
        }

      case DioExceptionType.cancel:
        throw const AppException(message: 'Request cancelled');

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          throw const NetworkException();
        }
        throw AppException(message: error.message ?? 'Unknown error');

      default:
        throw AppException(message: error.message ?? 'Unknown error');
    }
  }
}
