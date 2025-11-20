import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onetimesecret_flutter/core/errors/failures.dart';
import 'package:onetimesecret_flutter/domain/entities/secret.dart';
import 'package:onetimesecret_flutter/domain/repositories/secret_repository.dart';
import 'package:onetimesecret_flutter/domain/usecases/create_secret_usecase.dart';

@GenerateMocks([SecretRepository])
import 'create_secret_usecase_test.mocks.dart';

void main() {
  late CreateSecretUseCase usecase;
  late MockSecretRepository mockRepository;

  setUp(() {
    mockRepository = MockSecretRepository();
    usecase = CreateSecretUseCase(mockRepository);
  });

  final tSecret = Secret(
    secretKey: 'test-secret-key',
    metadataKey: 'test-metadata-key',
    value: 'test-secret-value',
    ttl: 3600,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );

  group('CreateSecretUseCase', () {
    test('should create a secret successfully', () async {
      // arrange
      when(mockRepository.createSecret(
        secret: anyNamed('secret'),
        passphrase: anyNamed('passphrase'),
        ttl: anyNamed('ttl'),
        recipient: anyNamed('recipient'),
      )).thenAnswer((_) async => Right(tSecret));

      // act
      final result = await usecase(
        secret: 'test-secret-value',
        passphrase: 'test-passphrase',
        ttl: 3600,
      );

      // assert
      expect(result, Right(tSecret));
      verify(mockRepository.createSecret(
        secret: 'test-secret-value',
        passphrase: 'test-passphrase',
        ttl: 3600,
        recipient: null,
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // arrange
      const tFailure = NetworkFailure();
      when(mockRepository.createSecret(
        secret: anyNamed('secret'),
        passphrase: anyNamed('passphrase'),
        ttl: anyNamed('ttl'),
        recipient: anyNamed('recipient'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(
        secret: 'test-secret-value',
        ttl: 3600,
      );

      // assert
      expect(result, const Left(tFailure));
      verify(mockRepository.createSecret(
        secret: 'test-secret-value',
        passphrase: null,
        ttl: 3600,
        recipient: null,
      ));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
