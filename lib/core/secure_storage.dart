import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  static const _tokenKey = 'ml_access_token';
  static const _ivKey = 'ml_iv_key';
  static const _deviceSaltKey = 'ml_device_salt';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey(_deviceSaltKey)) {
      await _prefs.setString(_deviceSaltKey, base64Encode(_randomBytes(32)));
    }
    _initialized = true;
  }

  Future<void> saveToken(String token) async {
    final key = _deriveKey();
    final iv = _randomBytes(16);
    final encrypted = _xor(utf8.encode(token), key, iv);
    await _prefs.setString(_tokenKey, base64Encode(encrypted));
    await _prefs.setString(_ivKey, base64Encode(iv));
  }

  Future<String?> readToken() async {
    final encStr = _prefs.getString(_tokenKey);
    final ivStr = _prefs.getString(_ivKey);
    if (encStr == null || ivStr == null) return null;
    try {
      final encrypted = base64Decode(encStr);
      final iv = base64Decode(ivStr);
      final key = _deriveKey();
      return utf8.decode(_xor(encrypted, key, iv));
    } catch (_) {
      await clearToken();
      return null;
    }
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_ivKey);
  }

  List<int> _deriveKey() {
    final salt = base64Decode(_prefs.getString(_deviceSaltKey)!);
    final raw = [...salt, ...utf8.encode('maxlond-2026-v1')];
    return sha256.convert(raw).bytes;
  }

  List<int> _randomBytes(int length) {
    final rand = Random.secure();
    return List<int>.generate(length, (_) => rand.nextInt(256));
  }

  List<int> _xor(List<int> data, List<int> key, List<int> iv) {
    final result = List<int>.filled(data.length, 0);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    return result;
  }
}