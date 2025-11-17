import 'package:flutter/foundation.dart';

/// Domain entity representing a one-time secret
@immutable
class Secret {
  final String? secretKey;
  final String? metadataKey;
  final String? value;
  final int? ttl;
  final String? recipient;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool? hasPassphrase;
  final String? state;

  const Secret({
    this.secretKey,
    this.metadataKey,
    this.value,
    this.ttl,
    this.recipient,
    this.createdAt,
    this.expiresAt,
    this.hasPassphrase,
    this.state,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Secret &&
          runtimeType == other.runtimeType &&
          secretKey == other.secretKey &&
          metadataKey == other.metadataKey;

  @override
  int get hashCode => secretKey.hashCode ^ metadataKey.hashCode;

  @override
  String toString() => 'Secret(secretKey: $secretKey, metadataKey: $metadataKey)';
}
