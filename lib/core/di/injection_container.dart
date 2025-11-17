import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/ots_remote_datasource.dart';
import '../../data/repositories/secret_repository_impl.dart';
import '../../domain/repositories/secret_repository.dart';
import '../../domain/usecases/create_secret.dart';
import '../../domain/usecases/retrieve_secret.dart';
import '../network/http_client.dart';
import '../security/secure_storage_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  getIt.registerLazySingleton<http.Client>(
    () => http.Client(),
  );

  getIt.registerLazySingleton<OTSHttpClient>(
    () => OTSHttpClient(
      client: getIt<http.Client>(),
      secureStorage: getIt<SecureStorageService>(),
    ),
  );

  // Data sources
  getIt.registerLazySingleton<OTSRemoteDataSource>(
    () => OTSRemoteDataSourceImpl(
      httpClient: getIt<OTSHttpClient>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<SecretRepository>(
    () => SecretRepositoryImpl(
      remoteDataSource: getIt<OTSRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => CreateSecret(getIt<SecretRepository>()));
  getIt.registerLazySingleton(() => RetrieveSecret(getIt<SecretRepository>()));
}
