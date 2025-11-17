import 'package:equatable/equatable.dart';

/// Domain entity representing a secret
class Secret extends Equatable {
  final String secretKey;
  final String metadataKey;
  final String? value;
  final int ttl;
  final String? recipient;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isReceived;
  final bool isBurned;
  final String? passphraseRequired;

  const Secret({
    required this.secretKey,
    required this.metadataKey,
    this.value,
    required this.ttl,
    this.recipient,
    required this.createdAt,
    this.expiresAt,
    this.isReceived = false,
    this.isBurned = false,
    this.passphraseRequired,
  });

  /// Check if the secret has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the secret requires a passphrase
  bool get requiresPassphrase => passphraseRequired != null;

  /// Get the share URL for this secret
  String getShareUrl(String baseUrl) {
    return '$baseUrl/secret/$secretKey';
  }

  /// Create a copy with updated fields
  Secret copyWith({
    String? secretKey,
    String? metadataKey,
    String? value,
    int? ttl,
    String? recipient,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isReceived,
    bool? isBurned,
    String? passphraseRequired,
  }) {
    return Secret(
      secretKey: secretKey ?? this.secretKey,
      metadataKey: metadataKey ?? this.metadataKey,
      value: value ?? this.value,
      ttl: ttl ?? this.ttl,
      recipient: recipient ?? this.recipient,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isReceived: isReceived ?? this.isReceived,
      isBurned: isBurned ?? this.isBurned,
      passphraseRequired: passphraseRequired ?? this.passphraseRequired,
    );
  }

  @override
  List<Object?> get props => [
        secretKey,
        metadataKey,
        value,
        ttl,
        recipient,
        createdAt,
        expiresAt,
        isReceived,
        isBurned,
        passphraseRequired,
      ];
}
