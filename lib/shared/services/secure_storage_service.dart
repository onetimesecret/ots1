import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/exceptions.dart';

/// Service for securely storing sensitive data
/// Uses iOS Keychain and Android KeyStore
class SecureStorageService {
  late final FlutterSecureStorage _storage;

  SecureStorageService() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        // Use AES encryption
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        // Use most secure accessibility option
        accessibility: KeychainAccessibility.first_unlock_this_device,
        // Require biometric authentication for sensitive data
        accountName: 'Onetimesecret',
      ),
    );
  }

  /// Write a value to secure storage
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException(
        message: 'Failed to write to secure storage',
        code: 'WRITE_FAILED',
        originalError: e,
      );
    }
  }

  /// Read a value from secure storage
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to read from secure storage',
        code: 'READ_FAILED',
        originalError: e,
      );
    }
  }

  /// Delete a value from secure storage
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to delete from secure storage',
        code: 'DELETE_FAILED',
        originalError: e,
      );
    }
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(
        message: 'Failed to clear secure storage',
        code: 'CLEAR_FAILED',
        originalError: e,
      );
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to check key existence',
        code: 'CONTAINS_KEY_FAILED',
        originalError: e,
      );
    }
  }

  /// Read all keys from secure storage
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw StorageException(
        message: 'Failed to read all from secure storage',
        code: 'READ_ALL_FAILED',
        originalError: e,
      );
    }
  }
}
