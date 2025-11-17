import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/secret.dart';
import '../../domain/repositories/secret_repository.dart';
import '../datasources/secret_remote_datasource.dart';
import '../models/create_secret_request.dart';

/// Implementation of SecretRepository
class SecretRepositoryImpl implements SecretRepository {
  final SecretRemoteDataSource remoteDataSource;

  SecretRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Secret>> createSecret({
    required String secret,
    String? passphrase,
    int? ttl,
    String? recipient,
  }) async {
    try {
      final request = CreateSecretRequest(
        secret: secret,
        passphrase: passphrase,
        ttl: ttl,
        recipient: recipient,
      );

      final result = await remoteDataSource.createSecret(request);
      return Right(result.toEntity());
    } on ApiException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
        code: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.code,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(ApiFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Secret>> getSecret({
    required String secretKey,
    String? passphrase,
  }) async {
    try {
      final result = await remoteDataSource.getSecret(
        secretKey: secretKey,
        passphrase: passphrase,
      );
      return Right(result.toEntity());
    } on ApiException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
        code: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.code,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(ApiFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Secret>> getMetadata({
    required String metadataKey,
  }) async {
    try {
      final result = await remoteDataSource.getMetadata(
        metadataKey: metadataKey,
      );
      return Right(result.toEntity());
    } on ApiException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
        code: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.code,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(ApiFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> burnSecret({
    required String metadataKey,
  }) async {
    try {
      await remoteDataSource.burnSecret(metadataKey: metadataKey);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
        code: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.code,
      ));
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(ApiFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }
}
