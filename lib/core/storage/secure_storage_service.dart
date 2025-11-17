import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../errors/exceptions.dart';

/// Secure storage service using platform-specific secure storage
/// iOS: Keychain Services
/// Android: EncryptedSharedPreferences
@singleton
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            // Use AES encryption for Android
            keyCipherAlgorithm:
                KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
            storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          ),
          iOptions: IOSOptions(
            // Use Keychain for iOS
            accessibility: KeychainAccessibility.first_unlock_this_device,
            accountName: 'OneTimeSecret',
          ),
        );

  /// Write a value to secure storage
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException(message: 'Failed to write to storage: $e');
    }
  }

  /// Read a value from secure storage
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to read from storage: $e');
    }
  }

  /// Delete a value from secure storage
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to delete from storage: $e');
    }
  }

  /// Check if a key exists in storage
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw StorageException(
          message: 'Failed to check key existence: $e');
    }
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(message: 'Failed to clear storage: $e');
    }
  }

  /// Read all values from secure storage
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw StorageException(message: 'Failed to read all from storage: $e');
    }
  }
}
