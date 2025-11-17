import 'package:get_it/get_it.dart';

import '../../shared/services/secure_storage_service.dart';
import '../network/api_client.dart';
import '../network/http_client_factory.dart';

final getIt = GetIt.instance;

/// Configure dependency injection
Future<void> configureDependencies() async {
  // Core Services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  // Network
  getIt.registerLazySingleton<HttpClientFactory>(
    () => HttpClientFactory(),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      httpClientFactory: getIt<HttpClientFactory>(),
      secureStorage: getIt<SecureStorageService>(),
    ),
  );

  // Repositories and use cases will be registered here as they're created
}
