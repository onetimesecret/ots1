import 'package:flutter_test/flutter_test.dart';
import 'package:onetimesecret/shared/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService secureStorage;

    setUp(() {
      secureStorage = SecureStorageService();
    });

    test('should write and read a value', () async {
      const key = 'test_key';
      const value = 'test_value';

      await secureStorage.write(key: key, value: value);
      final result = await secureStorage.read(key: key);

      expect(result, equals(value));
    });

    test('should return null for non-existent key', () async {
      const key = 'non_existent_key';

      final result = await secureStorage.read(key: key);

      expect(result, isNull);
    });

    test('should delete a value', () async {
      const key = 'test_key';
      const value = 'test_value';

      await secureStorage.write(key: key, value: value);
      await secureStorage.delete(key: key);
      final result = await secureStorage.read(key: key);

      expect(result, isNull);
    });

    test('should check if key exists', () async {
      const key = 'test_key';
      const value = 'test_value';

      await secureStorage.write(key: key, value: value);
      final exists = await secureStorage.containsKey(key: key);

      expect(exists, isTrue);
    });

    test('should return false for non-existent key', () async {
      const key = 'non_existent_key';

      final exists = await secureStorage.containsKey(key: key);

      expect(exists, isFalse);
    });
  });
}
