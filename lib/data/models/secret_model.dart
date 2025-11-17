import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/secret.dart';

part 'secret_model.g.dart';

/// Data model for Secret with JSON serialization
@JsonSerializable(fieldRename: FieldRename.snake)
class SecretModel extends Secret {
  const SecretModel({
    super.secretKey,
    super.metadataKey,
    super.value,
    super.ttl,
    super.recipient,
    super.createdAt,
    super.expiresAt,
    super.hasPassphrase,
    super.state,
  });

  /// Creates a SecretModel from JSON
  factory SecretModel.fromJson(Map<String, dynamic> json) =>
      _$SecretModelFromJson(json);

  /// Converts the model to JSON
  Map<String, dynamic> toJson() => _$SecretModelToJson(this);

  /// Converts the model to a domain entity
  Secret toEntity() => Secret(
        secretKey: secretKey,
        metadataKey: metadataKey,
        value: value,
        ttl: ttl,
        recipient: recipient,
        createdAt: createdAt,
        expiresAt: expiresAt,
        hasPassphrase: hasPassphrase,
        state: state,
      );

  /// Creates a model from a domain entity
  factory SecretModel.fromEntity(Secret secret) => SecretModel(
        secretKey: secret.secretKey,
        metadataKey: secret.metadataKey,
        value: secret.value,
        ttl: secret.ttl,
        recipient: secret.recipient,
        createdAt: secret.createdAt,
        expiresAt: secret.expiresAt,
        hasPassphrase: secret.hasPassphrase,
        state: secret.state,
      );
}
