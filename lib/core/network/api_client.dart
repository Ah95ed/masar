import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../demo/demo_service.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// عميل HTTP المركزي لإدارة طلبات تطبيق Maxlond Management
class ApiClient {
  final http.Client _httpClient;
  final SecureStorageService storageService;
  void Function()? onSessionExpired;

  /// User-Agent ثابت يحاكي متصفحاً حقيقياً لتجاوز حظر WAF
  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  ApiClient({
    http.Client? httpClient,
    required this.storageService,
    this.onSessionExpired,
  }) : _httpClient = httpClient ?? http.Client();

  /// تحديد ما إذا كان المسار تابعاً لـ auth.php أم management.php
  bool _isAuthRoute(String route) {
    return route == AppConstants.routeLogin ||
        route == AppConstants.routeLogout ||
        route == AppConstants.routeMe;
  }

  /// بناء رابط الطلب الكامل
  Uri _buildUri(String route, [Map<String, String>? queryParams]) {
    final baseUrl = _isAuthRoute(route)
        ? AppConstants.authBaseUrl
        : AppConstants.managementBaseUrl;

    final baseUri = Uri.parse(baseUrl);
    final mergedParams = Map<String, String>.from(baseUri.queryParameters);
    mergedParams['route'] = route;

    if (queryParams != null) {
      queryParams.forEach((key, value) {
        if (value.isNotEmpty) {
          mergedParams[key] = value;
        }
      });
    }

    return baseUri.replace(queryParameters: mergedParams);
  }

  /// المُرسل المركزي المتوافق أمنياً مع WAF وسيرفر الباك إند
  Future<http.Response> _sendRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    required bool requiresAuth,
    bool useAltHeader = false,
  }) async {
    final request = http.Request(method, uri);

    // 1. ترويسات نظيفة بدون أي Cookies
    request.headers.clear();
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = userAgent;
    request.headers['Cache-Control'] = 'no-store';

    // 2. تعيين Content-Type لطلبات POST فقط
    if (method == 'POST') {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = utf8.encode(jsonEncode(body ?? {}));
    }

    // 3. إضافة بيانات المصادقة (Bearer أو X-Auth-Token كبديل في حال حجب أباتشي)
    if (requiresAuth) {
      final token = await storageService.getToken();
      if (token != null && token.isNotEmpty) {
        if (useAltHeader) {
          request.headers['X-Auth-Token'] = token;
        } else {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    // ⚠️ منع وحذف الكوكيز بشكل قطعي لحماية الجلسة من حظر WAF
    request.headers.remove('Cookie');
    request.headers.remove('cookie');

    final streamed = await _httpClient
        .send(request)
        .timeout(const Duration(seconds: 25));

    return http.Response.fromStream(streamed);
  }

  /// طلب GET
  Future<dynamic> get(
    String route, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    if (DemoService.instance.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 250));
      return DemoService.instance.handleGet(route, queryParams);
    }

    try {
      final uri = _buildUri(route, queryParams);
      var response = await _sendRequest(
        method: 'GET',
        uri: uri,
        requiresAuth: requiresAuth,
      );

      // إذا رجع 401، إعادة المحاولة بترويسة X-Auth-Token
      if (response.statusCode == 401 && requiresAuth) {
        response = await _sendRequest(
          method: 'GET',
          uri: uri,
          requiresAuth: requiresAuth,
          useAltHeader: true,
        );
      }

      return _processResponse(response, route: route);
    } on SocketException {
      throw const ApiException.positional(
        null,
        'SOCKET_EXCEPTION',
        'تعذر الاتصال بخادم النظام (vehiclegate.ghusun.net). يرجى التأكد من تشغيل الإنترنت.',
      );
    } on HandshakeException {
      throw const ApiException.positional(
        null,
        'SSL_EXCEPTION',
        'تعذر التحقق من الاتصال المشفر بالخادم (SSL/TLS).',
      );
    } on TimeoutException {
      throw ApiException.timeout();
    } on FormatException {
      throw ApiException.unparseable();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'UNKNOWN_ERROR', message: 'حدث خطأ أثناء الاتصال: $e');
    }
  }

  /// طلب POST
  Future<dynamic> post(
    String route, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    if (DemoService.instance.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DemoService.instance.handlePost(route, body);
    }

    try {
      final uri = _buildUri(route, queryParams);
      var response = await _sendRequest(
        method: 'POST',
        uri: uri,
        body: body,
        requiresAuth: requiresAuth,
      );

      // إذا رجع 401، إعادة المحاولة بترويسة X-Auth-Token
      if (response.statusCode == 401 && requiresAuth) {
        response = await _sendRequest(
          method: 'POST',
          uri: uri,
          body: body,
          requiresAuth: requiresAuth,
          useAltHeader: true,
        );
      }

      return _processResponse(response, route: route);
    } on SocketException {
      throw const ApiException.positional(
        null,
        'SOCKET_EXCEPTION',
        'تعذر الاتصال بخادم النظام (vehiclegate.ghusun.net). يرجى التأكد من تشغيل الإنترنت.',
      );
    } on HandshakeException {
      throw const ApiException.positional(
        null,
        'SSL_EXCEPTION',
        'تعذر التحقق من الاتصال المشفر بالخادم (SSL/TLS).',
      );
    } on TimeoutException {
      throw ApiException.timeout();
    } on FormatException {
      throw ApiException.unparseable();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'UNKNOWN_ERROR', message: 'حدث خطأ أثناء إرسال البيانات: $e');
    }
  }

  /// معالجة استجابة الخادم وتفسير النجاح والخطأ
  dynamic _processResponse(http.Response response, {String? route}) {
    final contentType = response.headers['content-type'] ?? '';

    // التحقق من نوع الاستجابة وتجاوز أخطاء WAF (HTML responses)
    if (!contentType.contains('application/json')) {
      if (response.statusCode == 403) {
        throw const ApiException.positional(
          403,
          'forbidden_by_server',
          'تم رفض الطلب من الخادم أو جدار الحماية (WAF). حاول لاحقاً.',
        );
      }
      if (response.statusCode == 401) {
        if (route == AppConstants.routeMe) {
          storageService.deleteToken();
          onSessionExpired?.call();
        }
        throw const ApiException.positional(
          401,
          'unauthorized',
          'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.',
        );
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      throw ApiException.positional(
        response.statusCode,
        'invalid_response',
        'استجابة الخادم غير متوقعة (${response.statusCode})',
      );
    }

    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      throw ApiException.fromResponse(response.statusCode, null);
    }

    // التعامل مع رمز 401 بعد المحاولة البديلة
    if (response.statusCode == 401) {
      if (route == AppConstants.routeMe) {
        storageService.deleteToken();
        onSessionExpired?.call();
      }
      throw ApiException.fromResponse(401, decoded);
    }

    // 200 أو 201
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('success') && decoded['success'] == false) {
          throw ApiException.fromResponse(response.statusCode, decoded);
        }
        return decoded.containsKey('data') ? decoded['data'] : decoded;
      }
      return decoded;
    }

    // باقي رموز الخطأ (403, 404, 409, 422, 500)
    throw ApiException.fromResponse(response.statusCode, decoded);
  }
}