import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/network/http_client.dart';
import '../models/secret_model.dart';

/// Remote data source for OTS API operations
abstract class OTSRemoteDataSource {
  /// Creates a new secret on the server
  Future<SecretModel> createSecret({
    required String value,
    int? ttl,
    String? passphrase,
    String? recipient,
  });

  /// Retrieves and burns a secret from the server
  Future<SecretModel> retrieveSecret({
    required String secretKey,
    String? passphrase,
  });

  /// Gets secret metadata without burning it
  Future<SecretModel> getSecretMetadata({
    required String metadataKey,
  });

  /// Generates a random secret
  Future<SecretModel> generateSecret({
    String? passphrase,
    int? ttl,
    String? recipient,
  });

  /// Checks API status
  Future<bool> checkStatus();
}

/// Implementation of OTSRemoteDataSource
class OTSRemoteDataSourceImpl implements OTSRemoteDataSource {
  final OTSHttpClient httpClient;

  OTSRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<SecretModel> createSecret({
    required String value,
    int? ttl,
    String? passphrase,
    String? recipient,
  }) async {
    final body = <String, dynamic>{
      'secret': value,
      if (ttl != null) 'ttl': ttl,
      if (passphrase != null) 'passphrase': passphrase,
      if (recipient != null) 'recipient': recipient,
    };

    final response = await httpClient.post(
      ApiConstants.shareEndpoint,
      body: body,
    );

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return SecretModel.fromJson(jsonData);
  }

  @override
  Future<SecretModel> retrieveSecret({
    required String secretKey,
    String? passphrase,
  }) async {
    final queryParams = <String, String>{};
    if (passphrase != null) {
      queryParams['passphrase'] = passphrase;
    }

    final response = await httpClient.post(
      '${ApiConstants.secretEndpoint}/$secretKey',
      body: queryParams.isNotEmpty ? queryParams : null,
    );

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return SecretModel.fromJson(jsonData);
  }

  @override
  Future<SecretModel> getSecretMetadata({
    required String metadataKey,
  }) async {
    final response = await httpClient.get(
      '${ApiConstants.secretEndpoint}/$metadataKey',
    );

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return SecretModel.fromJson(jsonData);
  }

  @override
  Future<SecretModel> generateSecret({
    String? passphrase,
    int? ttl,
    String? recipient,
  }) async {
    final body = <String, dynamic>{
      if (ttl != null) 'ttl': ttl,
      if (passphrase != null) 'passphrase': passphrase,
      if (recipient != null) 'recipient': recipient,
    };

    final response = await httpClient.post(
      ApiConstants.generateEndpoint,
      body: body.isNotEmpty ? body : null,
    );

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return SecretModel.fromJson(jsonData);
  }

  @override
  Future<bool> checkStatus() async {
    try {
      final response = await httpClient.get(ApiConstants.statusEndpoint);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
