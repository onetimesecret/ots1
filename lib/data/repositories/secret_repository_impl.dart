import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_metadata.dart';
import '../../domain/repositories/secret_repository.dart';
import '../datasources/onetimesecret_api.dart';

/// Implementation of SecretRepository
@Singleton(as: SecretRepository)
class SecretRepositoryImpl implements SecretRepository {
  final OneTimeSecretApi _api;
  final NetworkInfo _networkInfo;

  SecretRepositoryImpl(
    this._api,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, Secret>> createSecret({
    required String secret,
    String? passphrase,
    int? ttl,
    String? recipient,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _api.createSecret(
        secret: secret,
        passphrase: passphrase,
        ttl: ttl,
        recipient: recipient,
      );
      return Right(result.toEntity());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message, code: e.code));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(message: e.message, code: e.code));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SecretMetadata>> getSecretMetadata({
    required String metadataKey,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _api.getSecretMetadata(metadataKey: metadataKey);
      return Right(result.toEntity());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message, code: e.code));
    } on SecretNotFoundException catch (e) {
      return Left(SecretNotFoundFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Secret>> revealSecret({
    required String secretKey,
    String? passphrase,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _api.revealSecret(
        secretKey: secretKey,
        passphrase: passphrase,
      );
      return Right(result.toEntity());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message, code: e.code));
    } on SecretNotFoundException catch (e) {
      return Left(SecretNotFoundFailure(message: e.message, code: e.code));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SecretMetadata>> burnSecret({
    required String metadataKey,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _api.burnSecret(metadataKey: metadataKey);
      return Right(result.toEntity());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message, code: e.code));
    } on SecretNotFoundException catch (e) {
      return Left(SecretNotFoundFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SecretMetadata>>> getRecentSecrets() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final results = await _api.getRecentSecrets();
      final entities = results.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Unknown error'));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateShareLink({
    required String secretKey,
  }) async {
    try {
      final shareUrl = 'https://onetimesecret.com/secret/$secretKey';
      return Right(shareUrl);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
