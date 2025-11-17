import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/secrets/data/datasources/secret_remote_datasource.dart';
import '../../features/secrets/data/repositories/secret_repository_impl.dart';
import '../../features/secrets/domain/repositories/secret_repository.dart';
import '../services/secure_storage_service.dart';

// Core Services
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => getIt<SecureStorageService>(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => getIt<ApiClient>(),
);

// Auth
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    secureStorage: ref.watch(secureStorageProvider),
  ),
);

// Secrets
final secretRemoteDataSourceProvider = Provider<SecretRemoteDataSource>(
  (ref) => SecretRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  ),
);

final secretRepositoryProvider = Provider<SecretRepository>(
  (ref) => SecretRepositoryImpl(
    remoteDataSource: ref.watch(secretRemoteDataSourceProvider),
  ),
);
