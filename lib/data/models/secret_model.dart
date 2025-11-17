import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/secret.dart';

part 'secret_model.g.dart';

/// Data model for Secret API responses
@JsonSerializable()
class SecretModel {
  @JsonKey(name: 'secret_key')
  final String secretKey;

  @JsonKey(name: 'metadata_key')
  final String metadataKey;

  @JsonKey(name: 'value')
  final String? value;

  @JsonKey(name: 'ttl')
  final int ttl;

  @JsonKey(name: 'recipient')
  final String? recipient;

  @JsonKey(name: 'created')
  final int created;

  @JsonKey(name: 'updated')
  final int? updated;

  @JsonKey(name: 'received')
  final bool? received;

  @JsonKey(name: 'passphrase_required')
  final String? passphraseRequired;

  const SecretModel({
    required this.secretKey,
    required this.metadataKey,
    this.value,
    required this.ttl,
    this.recipient,
    required this.created,
    this.updated,
    this.received,
    this.passphraseRequired,
  });

  factory SecretModel.fromJson(Map<String, dynamic> json) =>
      _$SecretModelFromJson(json);

  Map<String, dynamic> toJson() => _$SecretModelToJson(this);

  /// Convert to domain entity
  Secret toEntity() {
    final createdDate =
        DateTime.fromMillisecondsSinceEpoch(created * 1000);
    final expiresDate = createdDate.add(Duration(seconds: ttl));

    return Secret(
      secretKey: secretKey,
      metadataKey: metadataKey,
      value: value,
      ttl: ttl,
      recipient: recipient,
      createdAt: createdDate,
      expiresAt: expiresDate,
      isReceived: received ?? false,
      isBurned: false,
      passphraseRequired: passphraseRequired,
    );
  }
}
