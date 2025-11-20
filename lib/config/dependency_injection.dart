import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../core/network/dio_client.dart';
import '../core/network/network_info.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/datasources/onetimesecret_api.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/secret_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/secret_repository.dart';
import '../domain/usecases/burn_secret_usecase.dart';
import '../domain/usecases/create_secret_usecase.dart';
import '../domain/usecases/get_recent_secrets_usecase.dart';
import '../domain/usecases/reveal_secret_usecase.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/secret/secret_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Core
  getIt.registerSingleton<Logger>(Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  ));

  getIt.registerSingleton<SecureStorageService>(SecureStorageService());
  getIt.registerSingleton<Connectivity>(Connectivity());

  // Network
  getIt.registerSingleton<NetworkInfo>(
    NetworkInfoImpl(getIt<Connectivity>()),
  );

  getIt.registerSingleton<DioClient>(
    DioClient(
      getIt<SecureStorageService>(),
      getIt<Logger>(),
    ),
  );

  // API
  getIt.registerSingleton<OneTimeSecretApi>(
    OneTimeSecretApi(getIt<DioClient>().dio),
  );

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      getIt<SecureStorageService>(),
      getIt<OneTimeSecretApi>(),
      getIt<NetworkInfo>(),
    ),
  );

  getIt.registerSingleton<SecretRepository>(
    SecretRepositoryImpl(
      getIt<OneTimeSecretApi>(),
      getIt<NetworkInfo>(),
    ),
  );

  // Use Cases
  getIt.registerFactory(() => CreateSecretUseCase(getIt<SecretRepository>()));
  getIt.registerFactory(() => RevealSecretUseCase(getIt<SecretRepository>()));
  getIt.registerFactory(() => BurnSecretUseCase(getIt<SecretRepository>()));
  getIt.registerFactory(
      () => GetRecentSecretsUseCase(getIt<SecretRepository>()));

  // BLoCs
  getIt.registerFactory(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
    ),
  );

  getIt.registerFactory(
    () => SecretBloc(
      createSecretUseCase: getIt<CreateSecretUseCase>(),
      revealSecretUseCase: getIt<RevealSecretUseCase>(),
      burnSecretUseCase: getIt<BurnSecretUseCase>(),
      getRecentSecretsUseCase: getIt<GetRecentSecretsUseCase>(),
    ),
  );
}
