import 'package:flutter/material.dart';
import '../core/demo/demo_service.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  accessDenied,
}

/// موفر حالة المصادقة لإدارة دخول وخروج المدير العام (Maxlond Management)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider({
    required AuthService authService,
    required SecureStorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isAdmin => _currentUser?.role.toLowerCase() == 'admin' || _currentUser?.role.toLowerCase() == 'manager';
  bool get isDemoMode => DemoService.instance.isDemoMode;

  /// تسجيل الدخول بالوضع التجريبي (مدير عام فقط)
  Future<void> loginAsDemo() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    DemoService.instance.isDemoMode = true;
    DemoService.instance.currentRole = 'admin';

    _currentUser = UserModel.fromJson(DemoService.instance.currentUserJson);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// الخروج من الوضع التجريبي
  Future<void> exitDemoMode() async {
    DemoService.instance.isDemoMode = false;
    _currentUser = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// تهيئة التحقق من الجلسة المخزنة عند فتح التطبيق
  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final hasToken = await _authService.hasSavedToken();
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final user = await _authService.getMe();
      final role = user.role.toLowerCase().trim();
      if (role == 'admin' || role == 'manager' || role == 'مدير') {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        await _storageService.deleteToken();
        _status = AuthStatus.accessDenied;
        _errorMessage = 'هذا التطبيق مخصص للإدارة العامة فقط (Admin). تم رفض الدخول.';
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        _status = AuthStatus.accessDenied;
        _errorMessage = e.message;
      } else if (e.statusCode == 401) {
        await _storageService.deleteToken();
        _status = AuthStatus.unauthenticated;
        _errorMessage = e.message;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = e.message;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'تعذر التحقق من الجلسة الإدارية.';
    }

    notifyListeners();
  }

  /// تسجيل الدخول كمدير عام
  Future<bool> login({
    required String username,
    required String password,
    String? deviceInfo,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        username: username,
        password: password,
        deviceInfo: deviceInfo,
      );
      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        _status = AuthStatus.accessDenied;
        _errorMessage = e.message;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'فشل تسجيل الدخول. يرجى التأكد من البيانات أو الاتصال بالخادم.';
      notifyListeners();
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    if (DemoService.instance.isDemoMode) {
      DemoService.instance.isDemoMode = false;
    } else {
      await _authService.logout();
    }
    _currentUser = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// استدعاء عند انتهاء الجلسة التلقائي (401)
  void handleSessionExpired() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'انتهت جلسة الإدارة، يرجى تسجيل الدخول مجدداً.';
    notifyListeners();
  }

  /// قراءة رابط الخادم
  Future<String?> getSavedUsername() async => await _storageService.getUsername();

  Future<String> getBaseUrl() async {
    return await _storageService.getBaseUrl();
  }

  /// حفظ رابط الخادم
  Future<void> saveBaseUrl(String url) async {
    await _storageService.saveBaseUrl(url);
    notifyListeners();
  }
}
