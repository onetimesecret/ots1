import 'package:equatable/equatable.dart';

/// Domain entity representing secret metadata
class SecretMetadata extends Equatable {
  final String custid;
  final String metadataKey;
  final String secretKey;
  final int ttl;
  final DateTime metadataTtl;
  final String secretTtl;
  final String state;
  final DateTime updated;
  final DateTime created;
  final String? recipient;
  final bool passphraseRequired;

  const SecretMetadata({
    required this.custid,
    required this.metadataKey,
    required this.secretKey,
    required this.ttl,
    required this.metadataTtl,
    required this.secretTtl,
    required this.state,
    required this.updated,
    required this.created,
    this.recipient,
    required this.passphraseRequired,
  });

  /// Check if the metadata has been received
  bool get isReceived => state == 'received';

  /// Check if the secret has been burned
  bool get isBurned => state == 'burned';

  /// Check if the secret is still available
  bool get isAvailable => state == 'new' || state == 'received';

  @override
  List<Object?> get props => [
        custid,
        metadataKey,
        secretKey,
        ttl,
        metadataTtl,
        secretTtl,
        state,
        updated,
        created,
        recipient,
        passphraseRequired,
      ];
}
