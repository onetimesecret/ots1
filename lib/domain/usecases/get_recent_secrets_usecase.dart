import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../entities/secret_metadata.dart';
import '../repositories/secret_repository.dart';

/// Use case for getting recent secrets
@injectable
class GetRecentSecretsUseCase {
  final SecretRepository _repository;

  GetRecentSecretsUseCase(this._repository);

  Future<Either<Failure, List<SecretMetadata>>> call() async {
    return await _repository.getRecentSecrets();
  }
}
