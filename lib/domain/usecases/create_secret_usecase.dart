import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../entities/secret.dart';
import '../repositories/secret_repository.dart';

/// Use case for creating a new secret
@injectable
class CreateSecretUseCase {
  final SecretRepository _repository;

  CreateSecretUseCase(this._repository);

  Future<Either<Failure, Secret>> call({
    required String secret,
    String? passphrase,
    int? ttl,
    String? recipient,
  }) async {
    return await _repository.createSecret(
      secret: secret,
      passphrase: passphrase,
      ttl: ttl,
      recipient: recipient,
    );
  }
}
