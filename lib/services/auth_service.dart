import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

/// خدمة المصادقة الخاصة بتطبيق الإدارة Maxlond Management
class AuthService {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthService({
    required this.apiClient,
    required this.storageService,
  });

  /// تسجيل دخول المدير فقط
  Future<UserModel> login({
    required String username,
    required String password,
    String? deviceInfo,
  }) async {
    final payload = {
      'username': username.trim(),
      'password': password,
      'device_info': deviceInfo?.trim().isNotEmpty == true
          ? deviceInfo!.trim()
          : AppConstants.defaultDeviceInfo,
    };

    final response = await apiClient.post(
      AppConstants.routeLogin,
      body: payload,
      requiresAuth: false,
    );

    String? token;
    UserModel? user;

    if (response is Map<String, dynamic>) {
      token = response['token']?.toString();
      if (response['user'] != null && response['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(Map<String, dynamic>.from(response['user']));
      }
    }

    // إذا لم يتوفر كائن المستخدم في استجابة الدخول، نحفظ التوكن مؤقتاً لطلب getMe
    if (user == null && token != null) {
      await storageService.saveToken(token);
      try {
        user = await getMe();
      } catch (e) {
        await storageService.deleteToken();
        rethrow;
      }
    }

    if (user == null) {
      throw ApiException(message: 'تعذر استخراج بيانات المستخدم');
    }

    // شرط صارم: قبول دور admin فقط ورفض أي دور آخر
    final role = user.role.toLowerCase().trim();
    if (role != 'admin' && role != 'مدير' && role != 'manager') {
      // حذف أي توكن مخزن فوراً
      await storageService.deleteToken();
      throw ApiException(
        message: 'عذراً، هذا التطبيق مخصص للإدارة العامة فقط (Admin). لا يملك هذا الحساب صلاحية الدخول هنا.',
        statusCode: 403,
      );
    }

    // حفظ التوكن وبيانات المستخدم بعد نجاح التحقق من صلاحية المدير
    if (token != null && token.isNotEmpty) {
      await storageService.saveToken(token);
    }
    await storageService.saveUsername(user.username);

    return user;
  }

  /// جلب الملف الشخصي للتحقق من الجلسة والصلاحية
  Future<UserModel> getMe() async {
    final response = await apiClient.get(AppConstants.routeMe);
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      final role = user.role.toLowerCase().trim();
      if (role != 'admin' && role != 'مدير' && role != 'manager') {
        await storageService.deleteToken();
        throw ApiException(
          message: 'انتهت صلاحية الإدارة أو أن الحساب ليس لديه دور المدير العام.',
          statusCode: 403,
        );
      }
      return user;
    }
    throw ApiException(message: 'تعذر استخراج بيانات الملف الشخصي');
  }

  /// تسجيل الخروج عبر POST /api/auth.php?route=logout
  Future<void> logout() async {
    try {
      await apiClient.post(
        AppConstants.routeLogout,
        requiresAuth: true,
      );
    } catch (_) {
      // نضمن دائماً تفريغ التوكن والجلسة محلياً حتى في حال انقطاع الشبكة
    } finally {
      await storageService.deleteToken();
    }
  }

  /// التحقق من وجود توكن محفوظ
  Future<bool> hasSavedToken() async {
    final token = await storageService.getToken();
    return token != null && token.trim().isNotEmpty;
  }
}
