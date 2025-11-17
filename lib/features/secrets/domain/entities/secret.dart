import 'package:equatable/equatable.dart';

/// Domain entity representing a secret
class Secret extends Equatable {
  final String? metadataKey;
  final String? secretKey;
  final String? value;
  final int? ttl;
  final String? metadataTtl;
  final String? secretTtl;
  final String? recipient;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? passphrase;
  final bool? passphraseRequired;

  const Secret({
    this.metadataKey,
    this.secretKey,
    this.value,
    this.ttl,
    this.metadataTtl,
    this.secretTtl,
    this.recipient,
    this.createdAt,
    this.updatedAt,
    this.passphrase,
    this.passphraseRequired,
  });

  @override
  List<Object?> get props => [
        metadataKey,
        secretKey,
        value,
        ttl,
        metadataTtl,
        secretTtl,
        recipient,
        createdAt,
        updatedAt,
        passphrase,
        passphraseRequired,
      ];
}
