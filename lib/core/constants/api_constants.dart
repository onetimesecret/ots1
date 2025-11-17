/// API-specific constants and header keys
class ApiConstants {
  ApiConstants._();

  // HTTP Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerAuthorization = 'Authorization';
  static const String headerUserAgent = 'User-Agent';

  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormUrlEncoded =
      'application/x-www-form-urlencoded';

  // Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusTooManyRequests = 429;
  static const int statusInternalServerError = 500;
  static const int statusServiceUnavailable = 503;

  // User Agent
  static const String userAgent = 'OneTimeSecret-Flutter/1.0.0';

  // Query Parameters
  static const String paramSecretKey = 'secret_key';
  static const String paramMetadataKey = 'metadata_key';
  static const String paramPassphrase = 'passphrase';
  static const String paramTtl = 'ttl';
  static const String paramRecipient = 'recipient';
  static const String paramSecret = 'secret';
}
