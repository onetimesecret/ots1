import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onetimesecret/core/constants/app_constants.dart';
import 'package:onetimesecret/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:onetimesecret/shared/services/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('AuthRepository', () {
    late AuthRepositoryImpl authRepository;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      authRepository = AuthRepositoryImpl(secureStorage: mockSecureStorage);
    });

    group('storeCredentials', () {
      test('should store API key and username', () async {
        const apiKey = 'test_api_key';
        const username = 'test_user';

        when(() => mockSecureStorage.write(
              key: AppConstants.apiKeyStorageKey,
              value: apiKey,
            )).thenAnswer((_) async => {});

        when(() => mockSecureStorage.write(
              key: '${AppConstants.secureStorageKeyPrefix}username',
              value: username,
            )).thenAnswer((_) async => {});

        final result = await authRepository.storeCredentials(
          apiKey: apiKey,
          username: username,
        );

        expect(result.isRight(), isTrue);
        verify(() => mockSecureStorage.write(
              key: AppConstants.apiKeyStorageKey,
              value: apiKey,
            )).called(1);
        verify(() => mockSecureStorage.write(
              key: '${AppConstants.secureStorageKeyPrefix}username',
              value: username,
            )).called(1);
      });
    });

    group('getApiKey', () {
      test('should return stored API key', () async {
        const apiKey = 'test_api_key';

        when(() => mockSecureStorage.read(
              key: AppConstants.apiKeyStorageKey,
            )).thenAnswer((_) async => apiKey);

        final result = await authRepository.getApiKey();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success'),
          (value) => expect(value, equals(apiKey)),
        );
      });
    });

    group('isAuthenticated', () {
      test('should return true when API key exists', () async {
        when(() => mockSecureStorage.read(
              key: AppConstants.apiKeyStorageKey,
            )).thenAnswer((_) async => 'test_api_key');

        final result = await authRepository.isAuthenticated();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success'),
          (isAuthenticated) => expect(isAuthenticated, isTrue),
        );
      });

      test('should return false when API key is null', () async {
        when(() => mockSecureStorage.read(
              key: AppConstants.apiKeyStorageKey,
            )).thenAnswer((_) async => null);

        final result = await authRepository.isAuthenticated();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success'),
          (isAuthenticated) => expect(isAuthenticated, isFalse),
        );
      });
    });

    group('logout', () {
      test('should delete API key and username', () async {
        when(() => mockSecureStorage.delete(
              key: AppConstants.apiKeyStorageKey,
            )).thenAnswer((_) async => {});

        when(() => mockSecureStorage.delete(
              key: '${AppConstants.secureStorageKeyPrefix}username',
            )).thenAnswer((_) async => {});

        final result = await authRepository.logout();

        expect(result.isRight(), isTrue);
        verify(() => mockSecureStorage.delete(
              key: AppConstants.apiKeyStorageKey,
            )).called(1);
        verify(() => mockSecureStorage.delete(
              key: '${AppConstants.secureStorageKeyPrefix}username',
            )).called(1);
      });
    });
  });
}
