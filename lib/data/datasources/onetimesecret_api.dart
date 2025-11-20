import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/secret_model.dart';
import '../models/secret_metadata_model.dart';

part 'onetimesecret_api.g.dart';

/// OneTimeSecret API client using Retrofit
@RestApi()
abstract class OneTimeSecretApi {
  factory OneTimeSecretApi(Dio dio, {String? baseUrl}) = _OneTimeSecretApi;

  /// Create a new secret
  /// POST /share
  @POST('/share')
  @FormUrlEncoded()
  Future<SecretModel> createSecret({
    @Field('secret') required String secret,
    @Field('passphrase') String? passphrase,
    @Field('ttl') int? ttl,
    @Field('recipient') String? recipient,
  });

  /// Get secret metadata
  /// GET /private/{metadata_key}
  @GET('/private/{metadata_key}')
  Future<SecretMetadataModel> getSecretMetadata({
    @Path('metadata_key') required String metadataKey,
  });

  /// Reveal/consume a secret
  /// POST /secret/{secret_key}
  @POST('/secret/{secret_key}')
  @FormUrlEncoded()
  Future<SecretModel> revealSecret({
    @Path('secret_key') required String secretKey,
    @Field('passphrase') String? passphrase,
  });

  /// Burn/delete a secret
  /// POST /private/{metadata_key}/burn
  @POST('/private/{metadata_key}/burn')
  Future<SecretMetadataModel> burnSecret({
    @Path('metadata_key') required String metadataKey,
  });

  /// Get recent secrets
  /// GET /private/recent
  @GET('/private/recent')
  Future<List<SecretMetadataModel>> getRecentSecrets();

  /// Get API status
  /// GET /status
  @GET('/status')
  Future<Map<String, dynamic>> getStatus();

  /// Get API version
  /// GET /version
  @GET('/version')
  Future<Map<String, dynamic>> getVersion();

  /// Get supported locales
  /// GET /supported-locales
  @GET('/supported-locales')
  Future<List<String>> getSupportedLocales();
}
