import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Instancia con opciones de encriptación por defecto
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyApiKey = 'alma_user_api_key';
  static const String _keyProvider = 'alma_user_provider';

  /// Guarda la clave de API de forma encriptada
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _keyApiKey, value: apiKey);
  }

  /// Lee la clave de API encriptada
  static Future<String?> getApiKey() async {
    return await _storage.read(key: _keyApiKey);
  }

  /// Guarda el proveedor seleccionado (Claude, ChatGPT, Gemini)
  static Future<void> saveProvider(String providerName) async {
    await _storage.write(key: _keyProvider, value: providerName);
  }

  /// Lee el proveedor seleccionado
  static Future<String?> getProvider() async {
    return await _storage.read(key: _keyProvider);
  }

  /// Borra todos los datos guardados en la "Zona Peligrosa" de Ajustes
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}