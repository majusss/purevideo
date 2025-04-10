import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purevideo/core/utils/supported_enum.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getData(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteData(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearStorage() async {
    await _storage.deleteAll();
  }

  static Future<void> saveServiceData(
    SupportedService service,
    String key,
    String value,
  ) async {
    await _storage.write(key: '$service:$key', value: value);
  }

  static Future<String?> getServiceData(
    SupportedService service,
    String key,
  ) async {
    return await _storage.read(key: '$service:$key');
  }

  static Future<void> deleteServiceData(
    SupportedService service,
    String key,
  ) async {
    await _storage.delete(key: '$service:$key');
  }

  static Future<void> clearServiceStorage(SupportedService service) async {
    final allEntries = await _storage.readAll();
    for (final key in allEntries.keys) {
      if (key.startsWith('$service:')) {
        await _storage.delete(key: key);
      }
    }
  }
}
