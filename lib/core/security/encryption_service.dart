import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Service for handling encryption and hashing operations
class EncryptionService {
  /// Generate a SHA-256 hash of the input string
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a SHA-512 hash of the input string
  static String sha512Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  /// Generate HMAC-SHA256
  static String hmacSha256(String message, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Encrypt data using AES
  static String encryptAES(String plainText, String keyString) {
    final key = encrypt.Key.fromUtf8(keyString.padRight(32).substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt data using AES
  static String decryptAES(String encryptedText, String keyString) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw const FormatException('Invalid encrypted text format');
      }

      final key =
          encrypt.Key.fromUtf8(keyString.padRight(32).substring(0, 32));
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generate a random key
  static String generateRandomKey([int length = 32]) {
    final random = encrypt.SecureRandom(length);
    return base64Url.encode(random.bytes);
  }

  /// Validate password strength
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  /// Generate fingerprint for data
  static String generateFingerprint(Uint8List data) {
    final digest = sha256.convert(data);
    return base64Encode(digest.bytes);
  }
}
