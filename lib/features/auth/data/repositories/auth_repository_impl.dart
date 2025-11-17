import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({required this.secureStorage});

  @override
  Future<Either<Failure, void>> storeCredentials({
    required String apiKey,
    required String username,
  }) async {
    try {
      await secureStorage.write(
        key: AppConstants.apiKeyStorageKey,
        value: apiKey,
      );
      await secureStorage.write(
        key: '${AppConstants.secureStorageKeyPrefix}username',
        value: username,
      );
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to store credentials: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, String?>> getApiKey() async {
    try {
      final apiKey = await secureStorage.read(
        key: AppConstants.apiKeyStorageKey,
      );
      return Right(apiKey);
    } on StorageException catch (e) {
      return Left(StorageFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get API key: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, String?>> getUsername() async {
    try {
      final username = await secureStorage.read(
        key: '${AppConstants.secureStorageKeyPrefix}username',
      );
      return Right(username);
    } on StorageException catch (e) {
      return Left(StorageFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to get username: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final apiKey = await secureStorage.read(
        key: AppConstants.apiKeyStorageKey,
      );
      return Right(apiKey != null && apiKey.isNotEmpty);
    } on StorageException catch (e) {
      return Left(StorageFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to check authentication: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await secureStorage.delete(key: AppConstants.apiKeyStorageKey);
      await secureStorage.delete(
        key: '${AppConstants.secureStorageKeyPrefix}username',
      );
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to logout: $e',
      ));
    }
  }
}
