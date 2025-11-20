import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/secret_metadata.dart';

part 'secret_metadata_model.g.dart';

/// Data model for Secret Metadata API responses
@JsonSerializable()
class SecretMetadataModel {
  @JsonKey(name: 'custid')
  final String custid;

  @JsonKey(name: 'metadata_key')
  final String metadataKey;

  @JsonKey(name: 'secret_key')
  final String secretKey;

  @JsonKey(name: 'ttl')
  final int ttl;

  @JsonKey(name: 'metadata_ttl')
  final int metadataTtl;

  @JsonKey(name: 'secret_ttl')
  final String secretTtl;

  @JsonKey(name: 'state')
  final String state;

  @JsonKey(name: 'updated')
  final int updated;

  @JsonKey(name: 'created')
  final int created;

  @JsonKey(name: 'recipient')
  final String? recipient;

  @JsonKey(name: 'passphrase_required')
  final bool passphraseRequired;

  const SecretMetadataModel({
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

  factory SecretMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$SecretMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$SecretMetadataModelToJson(this);

  /// Convert to domain entity
  SecretMetadata toEntity() {
    return SecretMetadata(
      custid: custid,
      metadataKey: metadataKey,
      secretKey: secretKey,
      ttl: ttl,
      metadataTtl: DateTime.fromMillisecondsSinceEpoch(metadataTtl * 1000),
      secretTtl: secretTtl,
      state: state,
      updated: DateTime.fromMillisecondsSinceEpoch(updated * 1000),
      created: DateTime.fromMillisecondsSinceEpoch(created * 1000),
      recipient: recipient,
      passphraseRequired: passphraseRequired,
    );
  }
}
