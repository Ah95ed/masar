import '../core/secure_storage.dart';

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role']?.toString();
  String get displayName => _user?['full_name']?.toString() ?? _user?['username']?.toString() ?? 'مدير النظام';
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> restore() async {
    _token = await SecureStorage.instance.readToken();
  }

  Future<void> setSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    await SecureStorage.instance.saveToken(token);
  }

  void updateUser(Map<String, dynamic> user) => _user = user;

  Future<void> clear() async {
    _token = null;
    _user = null;
    await SecureStorage.instance.clearToken();
  }
}