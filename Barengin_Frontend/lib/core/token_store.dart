import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'barengin_sanctum_token';

  Future<String?> read() => _storage.read(key: _tokenKey);
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
