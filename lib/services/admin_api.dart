import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_exception.dart';
import '../core/constants.dart';
import 'session_manager.dart';

class AdminApi {
  AdminApi({
    this.origin = AppConstants.origin,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String origin;
  final http.Client _client;
  final _session = SessionManager.instance;

  Uri _authUri(String route) =>
      Uri.parse('$origin/api/auth.php?route=$route');

  Uri _mgmtUri(String route, [Map<String, String> q = const {}]) =>
      Uri.parse('$origin/api/management.php').replace(
        queryParameters: {'route': route, ...q},
      );

  // ============================================================
  // المصادقة
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = _authUri('login');
    final res = await _send(
      method: 'POST',
      uri: uri,
      body: {
        'username': username,
        'password': password,
        'device_info': AppConstants.deviceInfo,
      },
      includeAuth: false,
    );

    final data = _decode(res);
    final user = Map<String, dynamic>.from(data['user'] as Map);

    if (user['role'] != 'admin') {
      throw const ApiException(
        403,
        'role_not_allowed',
        'هذا التطبيق مخصص للمدير العام فقط (admin)',
      );
    }

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException(500, 'no_token', 'الخادم لم يرسل رمز التوكن');
    }

    await _session.setSession(token, user);
    return user;
  }

  Future<bool> restoreSession() async {
    await _session.restore();
    if (!_session.isAuthenticated) return false;
    try {
      final data = await _request('GET', _authUri('me'));
      _session.updateUser(Map<String, dynamic>.from(data as Map));
      return true;
    } on ApiException catch (e) {
      if (e.isAuthError) await _session.clear();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _request('GET', _authUri('me'));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> logout() async {
    try {
      if (_session.isAuthenticated) {
        await _request('POST', _authUri('logout'), body: const {});
      }
    } finally {
      await _session.clear();
    }
  }

  // ============================================================
  // الطلبات العامة
  // ============================================================

  Future<dynamic> get(String route, [Map<String, String> q = const {}]) =>
      _request('GET', _mgmtUri(route, q));

  Future<dynamic> post(String route, Map<String, dynamic> body) =>
      _request('POST', _mgmtUri(route), body: body);

  // ============================================================
  // التنفيذ الداخلي
  // ============================================================

  Future<dynamic> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    if (!_session.isAuthenticated) {
      throw const ApiException(
        401,
        'no_token',
        'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
      );
    }

    final res = await _send(
      method: method,
      uri: uri,
      body: body,
      includeAuth: true,
    );

    // عند 401: إعادة المحاولة تلقائياً بـ X-Auth-Token
    if (res.statusCode == 401 && !isRetry) {
      final retryRes = await _send(
        method: method,
        uri: uri,
        body: body,
        includeAuth: true,
        useAltHeader: true,
      );
      if (retryRes.statusCode == 401) {
        await _session.clear();
        throw const ApiException(
          401,
          'session_expired',
          'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
        );
      }
      return _decode(retryRes);
    }

    if (res.statusCode == 401) {
      await _session.clear();
    }

    return _decode(res);
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    required bool includeAuth,
    bool useAltHeader = false,
  }) async {
    final request = http.Request(method, uri);

    request.headers.clear();
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = AppConstants.userAgent;
    request.headers['Cache-Control'] = 'no-store';

    if (method == 'POST') {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = utf8.encode(jsonEncode(body ?? {}));
    }

    if (includeAuth) {
      final token = _session.token;
      if (token == null) {
        throw const ApiException(401, 'no_token', 'لا يوجد توكن محفوظ');
      }
      if (useAltHeader) {
        request.headers['X-Auth-Token'] = token;
      } else {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    // ⚠️ منع الكوكيز نهائياً لتفادي حظر WAF
    request.headers.remove('Cookie');
    request.headers.remove('cookie');

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 25));
      return await http.Response.fromStream(streamed);
    } on Exception {
      throw const ApiException(
        0,
        'network_error',
        'تعذر الاتصال بالخادم، تحقق من اتصال الإنترنت',
      );
    }
  }

  dynamic _decode(http.Response res) {
    final contentType = res.headers['content-type'] ?? '';

    if (!contentType.contains('application/json')) {
      if (res.statusCode == 403) {
        throw const ApiException(403, 'forbidden', 'تم رفض الطلب من الخادم أو WAF');
      }
      if (res.statusCode == 401) {
        throw const ApiException(401, 'unauthorized', 'انتهت صلاحية الجلسة');
      }
      throw ApiException(res.statusCode, 'invalid_response', 'استجابة الخادم غير متوقعة');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(res.statusCode, 'invalid_json', 'استجابة الخادم غير صالحة');
    }

    if (json['success'] == true) {
      return json['data'];
    }

    final err = json['error'];
    final code = err is Map ? '${err['code']}' : 'request_failed';
    final msg = err is Map ? '${err['message']}' : 'تعذر تنفيذ الطلب';
    throw ApiException(res.statusCode, code, msg);
  }
}