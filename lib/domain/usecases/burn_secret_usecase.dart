import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../entities/secret_metadata.dart';
import '../repositories/secret_repository.dart';

/// Use case for burning/deleting a secret
@injectable
class BurnSecretUseCase {
  final SecretRepository _repository;

  BurnSecretUseCase(this._repository);

  Future<Either<Failure, SecretMetadata>> call({
    required String metadataKey,
  }) async {
    return await _repository.burnSecret(metadataKey: metadataKey);
  }
}
