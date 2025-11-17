/// Request model for creating a secret
class CreateSecretRequest {
  final String secret;
  final String? passphrase;
  final int? ttl;
  final String? recipient;

  const CreateSecretRequest({
    required this.secret,
    this.passphrase,
    this.ttl,
    this.recipient,
  });

  Map<String, dynamic> toJson() {
    return {
      'secret': secret,
      if (passphrase != null && passphrase!.isNotEmpty)
        'passphrase': passphrase,
      if (ttl != null) 'ttl': ttl,
      if (recipient != null && recipient!.isNotEmpty) 'recipient': recipient,
    };
  }
}
