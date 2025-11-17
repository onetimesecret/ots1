import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/exceptions.dart';

/// Service for secure storage operations using platform-specific secure storage
/// - Android: Uses Android Keystore
/// - iOS: Uses iOS Keychain
class SecureStorageService {
  late final FlutterSecureStorage _storage;

  SecureStorageService() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  /// Writes a key-value pair to secure storage
  ///
  /// Throws [StorageException] if the operation fails
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException(
        message: 'Failed to write to secure storage: ${e.toString()}',
      );
    }
  }

  /// Reads a value from secure storage
  ///
  /// Returns null if the key doesn't exist
  /// Throws [StorageException] if the operation fails
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to read from secure storage: ${e.toString()}',
      );
    }
  }

  /// Deletes a key-value pair from secure storage
  ///
  /// Throws [StorageException] if the operation fails
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to delete from secure storage: ${e.toString()}',
      );
    }
  }

  /// Deletes all key-value pairs from secure storage
  ///
  /// Use with caution! This will clear all stored credentials.
  /// Throws [StorageException] if the operation fails
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(
        message: 'Failed to clear secure storage: ${e.toString()}',
      );
    }
  }

  /// Checks if a key exists in secure storage
  ///
  /// Returns true if the key exists, false otherwise
  /// Throws [StorageException] if the operation fails
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw StorageException(
        message: 'Failed to check key in secure storage: ${e.toString()}',
      );
    }
  }

  /// Reads all key-value pairs from secure storage
  ///
  /// Returns a Map of all stored values
  /// Throws [StorageException] if the operation fails
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw StorageException(
        message: 'Failed to read all from secure storage: ${e.toString()}',
      );
    }
  }
}
