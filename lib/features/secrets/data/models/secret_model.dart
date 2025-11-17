import '../../domain/entities/secret.dart';

/// Data model for Secret with JSON serialization
class SecretModel extends Secret {
  const SecretModel({
    super.metadataKey,
    super.secretKey,
    super.value,
    super.ttl,
    super.metadataTtl,
    super.secretTtl,
    super.recipient,
    super.createdAt,
    super.updatedAt,
    super.passphrase,
    super.passphraseRequired,
  });

  factory SecretModel.fromJson(Map<String, dynamic> json) {
    return SecretModel(
      metadataKey: json['metadata_key'] as String?,
      secretKey: json['secret_key'] as String?,
      value: json['value'] as String?,
      ttl: json['ttl'] as int?,
      metadataTtl: json['metadata_ttl'] as String?,
      secretTtl: json['secret_ttl'] as String?,
      recipient: json['recipient'] as String?,
      createdAt: json['created'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created'] as int)
          : null,
      updatedAt: json['updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated'] as int)
          : null,
      passphrase: json['passphrase'] as String?,
      passphraseRequired: json['passphrase_required'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (metadataKey != null) 'metadata_key': metadataKey,
      if (secretKey != null) 'secret_key': secretKey,
      if (value != null) 'value': value,
      if (ttl != null) 'ttl': ttl,
      if (metadataTtl != null) 'metadata_ttl': metadataTtl,
      if (secretTtl != null) 'secret_ttl': secretTtl,
      if (recipient != null) 'recipient': recipient,
      if (createdAt != null) 'created': createdAt!.millisecondsSinceEpoch,
      if (updatedAt != null) 'updated': updatedAt!.millisecondsSinceEpoch,
      if (passphrase != null) 'passphrase': passphrase,
      if (passphraseRequired != null) 'passphrase_required': passphraseRequired,
    };
  }

  Secret toEntity() {
    return Secret(
      metadataKey: metadataKey,
      secretKey: secretKey,
      value: value,
      ttl: ttl,
      metadataTtl: metadataTtl,
      secretTtl: secretTtl,
      recipient: recipient,
      createdAt: createdAt,
      updatedAt: updatedAt,
      passphrase: passphrase,
      passphraseRequired: passphraseRequired,
    );
  }
}
