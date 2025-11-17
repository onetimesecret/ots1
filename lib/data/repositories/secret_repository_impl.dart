import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/secret.dart';
import '../../domain/repositories/secret_repository.dart';
import '../datasources/ots_remote_datasource.dart';

/// Implementation of SecretRepository
class SecretRepositoryImpl implements SecretRepository {
  final OTSRemoteDataSource remoteDataSource;

  SecretRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Secret> createSecret({
    required String value,
    int? ttl,
    String? passphrase,
    String? recipient,
  }) async {
    try {
      final secretModel = await remoteDataSource.createSecret(
        value: value,
        ttl: ttl,
        passphrase: passphrase,
        recipient: recipient,
      );
      return secretModel.toEntity();
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } on ValidationException catch (e) {
      throw ValidationFailure(message: e.message, statusCode: e.statusCode);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnknownFailure(message: 'Failed to create secret: ${e.toString()}');
    }
  }

  @override
  Future<Secret> retrieveSecret({
    required String secretKey,
    String? passphrase,
  }) async {
    try {
      final secretModel = await remoteDataSource.retrieveSecret(
        secretKey: secretKey,
        passphrase: passphrase,
      );
      return secretModel.toEntity();
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } on NotFoundException catch (e) {
      throw NotFoundFailure(message: e.message, statusCode: e.statusCode);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnknownFailure(
        message: 'Failed to retrieve secret: ${e.toString()}',
      );
    }
  }

  @override
  Future<Secret> getSecretMetadata({
    required String metadataKey,
  }) async {
    try {
      final secretModel = await remoteDataSource.getSecretMetadata(
        metadataKey: metadataKey,
      );
      return secretModel.toEntity();
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on NotFoundException catch (e) {
      throw NotFoundFailure(message: e.message, statusCode: e.statusCode);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnknownFailure(
        message: 'Failed to get metadata: ${e.toString()}',
      );
    }
  }

  @override
  Future<Secret> generateSecret({
    String? passphrase,
    int? ttl,
    String? recipient,
  }) async {
    try {
      final secretModel = await remoteDataSource.generateSecret(
        passphrase: passphrase,
        ttl: ttl,
        recipient: recipient,
      );
      return secretModel.toEntity();
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnknownFailure(
        message: 'Failed to generate secret: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> checkStatus() async {
    try {
      return await remoteDataSource.checkStatus();
    } catch (_) {
      return false;
    }
  }
}
