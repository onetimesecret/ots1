import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onetimesecret_flutter/core/errors/exceptions.dart';
import 'package:onetimesecret_flutter/core/errors/failures.dart';
import 'package:onetimesecret_flutter/core/network/network_info.dart';
import 'package:onetimesecret_flutter/data/datasources/onetimesecret_api.dart';
import 'package:onetimesecret_flutter/data/models/secret_model.dart';
import 'package:onetimesecret_flutter/data/repositories/secret_repository_impl.dart';

@GenerateMocks([OneTimeSecretApi, NetworkInfo])
import 'secret_repository_impl_test.mocks.dart';

void main() {
  late SecretRepositoryImpl repository;
  late MockOneTimeSecretApi mockApi;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockApi = MockOneTimeSecretApi();
    mockNetworkInfo = MockNetworkInfo();
    repository = SecretRepositoryImpl(mockApi, mockNetworkInfo);
  });

  final tSecretModel = SecretModel(
    secretKey: 'test-secret-key',
    metadataKey: 'test-metadata-key',
    value: 'test-secret-value',
    ttl: 3600,
    created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );

  group('createSecret', () {
    test('should check if device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockApi.createSecret(
        secret: anyNamed('secret'),
        passphrase: anyNamed('passphrase'),
        ttl: anyNamed('ttl'),
        recipient: anyNamed('recipient'),
      )).thenAnswer((_) async => tSecretModel);

      // act
      await repository.createSecret(
        secret: 'test-secret-value',
        ttl: 3600,
      );

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    test('should return secret when API call is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockApi.createSecret(
        secret: anyNamed('secret'),
        passphrase: anyNamed('passphrase'),
        ttl: anyNamed('ttl'),
        recipient: anyNamed('recipient'),
      )).thenAnswer((_) async => tSecretModel);

      // act
      final result = await repository.createSecret(
        secret: 'test-secret-value',
        ttl: 3600,
      );

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (secret) {
          expect(secret.secretKey, tSecretModel.secretKey);
          expect(secret.metadataKey, tSecretModel.metadataKey);
          expect(secret.value, tSecretModel.value);
        },
      );
    });

    test('should return NetworkFailure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.createSecret(
        secret: 'test-secret-value',
        ttl: 3600,
      );

      // assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(mockApi.createSecret(
        secret: anyNamed('secret'),
        passphrase: anyNamed('passphrase'),
        ttl: anyNamed('ttl'),
        recipient: anyNamed('recipient'),
      ));
    });

    test('should return AuthenticationFailure when API throws AuthenticationException',
        () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockApi.createSecret(
        secret: anyNamed('secret'),
        passphrase: anyNamed('passphrase'),
        ttl: anyNamed('ttl'),
        recipient: anyNamed('recipient'),
      )).thenThrow(const AuthenticationException());

      // act
      final result = await repository.createSecret(
        secret: 'test-secret-value',
        ttl: 3600,
      );

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (secret) => fail('Should not return secret'),
      );
    });
  });
}
