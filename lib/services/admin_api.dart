import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

class AdminApi {
  AdminApi({
    String? origin,
    http.Client? client,
  })  : origin = origin ?? 'https://vehiclegate.ghusun.net',
        _client = client ?? http.Client();

  final String origin;
  final http.Client _client;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  /// User-Agent ثابت يحاكي متصفحاً حقيقياً —
  /// بعض WAFs تحجب User-Agent الافتراضي لـ Dart.
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  Uri _authUri(String route) =>
      Uri.parse('$origin/api/auth.php?route=$route');

  Uri _mgmtUri(String route, [Map<String, String> q = const {}]) =>
      Uri.parse('$origin/api/management.php').replace(
        queryParameters: {'route': route, ...q},
      );

  Future<String?> _token() => _storage.read(key: _tokenKey);

  Future<void> _saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> _clearToken() => _storage.delete(key: _tokenKey);

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
        'device_info': 'Maxlond Management / Flutter',
      },
      includeAuth: false,
    );
    final data = _decode(res);
    final user = Map<String, dynamic>.from(data['user'] as Map);
    if (user['role'] != 'admin') {
      throw const ApiException.positional(
        403,
        'role_not_allowed',
        'هذا التطبيق مخصص للمدير فقط',
      );
    }
    await _saveToken(data['token'] as String);
    return user;
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _request('GET', _authUri('me'));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> logout() async {
    try {
      await _request('POST', _authUri('logout'), body: const {});
    } finally {
      await _clearToken();
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
    final res = await _send(
      method: method,
      uri: uri,
      body: body,
      includeAuth: true,
    );

    // 401 → إعادة محاولة بـ X-Auth-Token
    if (res.statusCode == 401 && !isRetry) {
      final token = await _token();
      if (token != null) {
        final retryRes = await _send(
          method: method,
          uri: uri,
          body: body,
          includeAuth: true,
          useAltHeader: true,
        );
        return _decode(retryRes);
      }
    }

    return _decode(res);
  }

  /// المُرسل المركزي — يستخدم `http.Request` لضمان عدم إرسال Cookie.
  Future<http.Response> _send({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    required bool includeAuth,
    bool useAltHeader = false,
  }) async {
    final request = http.Request(method, uri);

    // ترويسات نظيفة — بدون Cookie
    request.headers.clear();
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = _userAgent;
    request.headers['Cache-Control'] = 'no-store';

    if (method == 'POST') {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = utf8.encode(jsonEncode(body ?? {}));
    }

    if (includeAuth) {
      final token = await _token();
      if (token != null) {
        if (useAltHeader) {
          request.headers['X-Auth-Token'] = token;
        } else {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    // ⚠️ نقطة حرجة: تأكد من عدم إرسال Cookie
    request.headers.remove('Cookie');
    request.headers.remove('cookie');

    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));

    return http.Response.fromStream(streamed);
  }

  // ============================================================
  // تحليل الاستجابة
  // ============================================================

  dynamic _decode(http.Response res) {
    final contentType = res.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (res.statusCode == 403) {
        throw const ApiException.positional(
          403,
          'forbidden_by_server',
          'تم رفض الطلب من الخادم. حاول لاحقاً.',
        );
      }
      if (res.statusCode == 401) {
        throw const ApiException.positional(
          401,
          'unauthorized',
          'انتهت الجلسة. أعد تسجيل الدخول.',
        );
      }
      throw ApiException.positional(
        res.statusCode,
        'invalid_response',
        'استجابة الخادم غير متوقعة',
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException.positional(
        res.statusCode,
        'invalid_json',
        'استجابة الخادم غير صالحة',
      );
    }

    if (json['success'] == true) {
      return json['data'];
    }

    final err = json['error'];
    final code = err is Map ? '${err['code']}' : 'request_failed';
    final msg = err is Map ? '${err['message']}' : 'تعذر تنفيذ الطلب';
    throw ApiException.positional(res.statusCode, code, msg);
  }
}