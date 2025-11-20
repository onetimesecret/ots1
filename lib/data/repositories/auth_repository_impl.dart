import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_credentials.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/onetimesecret_api.dart';

/// Implementation of AuthRepository
@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SecureStorageService _secureStorage;
  final OneTimeSecretApi _api;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl(
    this._secureStorage,
    this._api,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, void>> saveCredentials({
    required UserCredentials credentials,
  }) async {
    try {
      await _secureStorage.write(
        key: AppConstants.storageKeyUsername,
        value: credentials.username,
      );
      await _secureStorage.write(
        key: AppConstants.storageKeyApiKey,
        value: credentials.apiKey,
      );
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredentials?>> getCredentials() async {
    try {
      final username =
          await _secureStorage.read(key: AppConstants.storageKeyUsername);
      final apiKey =
          await _secureStorage.read(key: AppConstants.storageKeyApiKey);

      if (username == null || apiKey == null) {
        return const Right(null);
      }

      return Right(
        UserCredentials(username: username, apiKey: apiKey),
      );
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCredentials() async {
    try {
      await _secureStorage.delete(key: AppConstants.storageKeyUsername);
      await _secureStorage.delete(key: AppConstants.storageKeyApiKey);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final credentials = await getCredentials();
      return credentials.fold(
        (failure) => Left(failure),
        (creds) => Right(creds != null),
      );
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> validateCredentials({
    required UserCredentials credentials,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Save credentials temporarily
      await _secureStorage.write(
        key: AppConstants.storageKeyUsername,
        value: credentials.username,
      );
      await _secureStorage.write(
        key: AppConstants.storageKeyApiKey,
        value: credentials.apiKey,
      );

      // Try to get status to validate credentials
      await _api.getStatus();
      return const Right(true);
    } on AuthenticationException {
      // Remove invalid credentials
      await deleteCredentials();
      return const Right(false);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
