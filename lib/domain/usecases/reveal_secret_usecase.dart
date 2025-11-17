import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../entities/secret.dart';
import '../repositories/secret_repository.dart';

/// Use case for revealing/consuming a secret
@injectable
class RevealSecretUseCase {
  final SecretRepository _repository;

  RevealSecretUseCase(this._repository);

  Future<Either<Failure, Secret>> call({
    required String secretKey,
    String? passphrase,
  }) async {
    return await _repository.revealSecret(
      secretKey: secretKey,
      passphrase: passphrase,
    );
  }
}
