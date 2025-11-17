// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretModel _$SecretModelFromJson(Map<String, dynamic> json) => SecretModel(
      secretKey: json['secret_key'] as String?,
      metadataKey: json['metadata_key'] as String?,
      value: json['value'] as String?,
      ttl: json['ttl'] as int?,
      recipient: json['recipient'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      hasPassphrase: json['has_passphrase'] as bool?,
      state: json['state'] as String?,
    );

Map<String, dynamic> _$SecretModelToJson(SecretModel instance) =>
    <String, dynamic>{
      'secret_key': instance.secretKey,
      'metadata_key': instance.metadataKey,
      'value': instance.value,
      'ttl': instance.ttl,
      'recipient': instance.recipient,
      'created_at': instance.createdAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'has_passphrase': instance.hasPassphrase,
      'state': instance.state,
    };
