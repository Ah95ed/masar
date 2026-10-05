import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// خدمة التخزين الآمن لحفظ توكن المدير وإعدادات النطاق
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// حفظ التوكن
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.keyToken, value: token);
  }

  /// جلب التوكن
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.keyToken);
    } catch (_) {
      return null;
    }
  }

  /// حذف التوكن عند تسجيل الخروج أو انتهاء الجلسة
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.keyToken);
    } catch (_) {}
  }

  /// حفظ نطاق الخادم
  Future<void> saveDomain(String domain) async {
    await _storage.write(key: AppConstants.keyDomain, value: domain.trim());
  }

  /// قراءة نطاق الخادم
  Future<String> getDomain() async {
    try {
      final saved = await _storage.read(key: AppConstants.keyDomain);
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim();
      }
    } catch (_) {}
    return AppConstants.defaultDomain;
  }

  // توافق مع getBaseUrl / saveBaseUrl
  Future<void> saveBaseUrl(String url) => saveDomain(url);
  Future<String> getBaseUrl() => getDomain();

  /// حفظ اسم المستخدم
  Future<void> saveUsername(String username) async {
    await _storage.write(key: AppConstants.keyUsername, value: username.trim());
  }

  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: AppConstants.keyUsername);
    } catch (_) {
      return null;
    }
  }

  /// مسح جميع البيانات المخزنة
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}