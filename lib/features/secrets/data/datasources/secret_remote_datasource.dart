import '../../../../core/network/api_client.dart';
import '../models/create_secret_request.dart';
import '../models/secret_model.dart';

/// Remote data source for secret operations
class SecretRemoteDataSource {
  final ApiClient apiClient;

  SecretRemoteDataSource({required this.apiClient});

  /// Create a new secret
  Future<SecretModel> createSecret(CreateSecretRequest request) async {
    final response = await apiClient.post(
      '/share',
      data: request.toJson(),
    );

    return SecretModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Retrieve a secret by key
  Future<SecretModel> getSecret({
    required String secretKey,
    String? passphrase,
  }) async {
    final response = await apiClient.post(
      '/secret/$secretKey',
      data: passphrase != null ? {'passphrase': passphrase} : null,
    );

    return SecretModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get secret metadata
  Future<SecretModel> getMetadata({required String metadataKey}) async {
    final response = await apiClient.post(
      '/private/$metadataKey',
    );

    return SecretModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Burn a secret (delete it before it expires)
  Future<void> burnSecret({required String metadataKey}) async {
    await apiClient.post(
      '/private/$metadataKey/burn',
    );
  }
}
