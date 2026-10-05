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

  /// بناء رابط الطلب الكامل بناءً على النطاق المحفوظ
  Future<Uri> _buildUri(String route, [Map<String, String>? queryParams]) async {
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

  /// ترويسات الطلب
  Future<Map<String, String>> _buildHeaders({bool isJson = true, bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (requiresAuth) {
      final token = await storageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
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
      final uri = await _buildUri(route, queryParams);
      final headers = await _buildHeaders(isJson: false, requiresAuth: requiresAuth);

      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 25));

      return _processResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on TimeoutException {
      throw ApiException.timeout();
    } on FormatException {
      throw ApiException.unparseable();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'حدث خطأ أثناء الاتصال: $e');
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
      final uri = await _buildUri(route, queryParams);
      final headers = await _buildHeaders(isJson: true, requiresAuth: requiresAuth);

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 25));

      return _processResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on TimeoutException {
      throw ApiException.timeout();
    } on FormatException {
      throw ApiException.unparseable();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'حدث خطأ أثناء إرسال البيانات: $e');
    }
  }

  /// معالجة استجابة الخادم وتفسير النجاح والخطأ
  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      throw ApiException.fromResponse(response.statusCode, null);
    }

    // التعامل مع رمز 401
    if (response.statusCode == 401) {
      storageService.deleteToken();
      if (onSessionExpired != null) {
        onSessionExpired!();
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

    // باقي رموز الخطأ
    throw ApiException.fromResponse(response.statusCode, decoded);
  }
}
