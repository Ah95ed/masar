/// استثناء مخصص للتعامل مع أخطاء الـ API والشبكة بأسلوب موحد وواضح
class ApiException implements Exception {
  final int? statusCode;
  final String? code;
  final String message;
  final dynamic details;

  ApiException({
    this.statusCode,
    this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;

  /// تحويل كود الخطأ أو رمز الحالة إلى رسالة عربية مفهومة للمستخدم
  factory ApiException.fromResponse(int statusCode, dynamic jsonBody) {
    String? errorCode;
    String arabicMessage = 'حدث خطأ أثناء معالجة الطلب.';
    dynamic details;

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody.containsKey('error') && jsonBody['error'] is Map<String, dynamic>) {
        final errorMap = jsonBody['error'] as Map<String, dynamic>;
        errorCode = errorMap['code']?.toString();
        if (errorMap['message'] != null && errorMap['message'].toString().trim().isNotEmpty) {
          arabicMessage = errorMap['message'].toString();
        }
        details = errorMap['details'];
      } else if (jsonBody.containsKey('message') && jsonBody['message'] != null) {
        arabicMessage = jsonBody['message'].toString();
      }
    }

    // تخصيص الرسائل بناء على رمز HTTP إذا لم تكن هناك رسالة واضحة من السيرفر
    switch (statusCode) {
      case 401:
        arabicMessage = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.';
        break;
      case 403:
        arabicMessage = (errorCode == 'ACCOUNT_NOT_APPROVED' ||
                arabicMessage.contains('معتمد') ||
                arabicMessage.contains('موافقة'))
            ? 'الحساب قيد المراجعة والاعتماد من قبل الإدارة.'
            : 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
        break;
      case 404:
        arabicMessage = 'العنصر المطلوب غير موجود أو تم حذفه.';
        break;
      case 409:
        arabicMessage = 'التقرير معتمد ومقفل ولا يمكن تعديله. يتطلب مراجعة المدير.';
        break;
      case 422:
        if (arabicMessage == 'حدث خطأ أثناء معالجة الطلب.') {
          arabicMessage = 'البيانات المدخلة غير صحيحة، يرجى مراجعة الحقول المطلوبة.';
        }
        break;
      case 429:
        arabicMessage = 'تجاوزت الحد المسموح من المحاولات، يرجى الانتظار قليلاً ثم المحاولة مجدداً.';
        break;
      case 500:
      case 502:
      case 503:
        arabicMessage = 'خطأ في خادم النظام، يرجى المحاولة لاحقاً.';
        break;
    }

    return ApiException(
      statusCode: statusCode,
      code: errorCode,
      message: arabicMessage,
      details: details,
    );
  }

  factory ApiException.networkError() {
    return ApiException(
      statusCode: null,
      code: 'NETWORK_ERROR',
      message: 'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مجدداً.',
    );
  }

  factory ApiException.timeout() {
    return ApiException(
      statusCode: 408,
      code: 'TIMEOUT',
      message: 'استغرق الطلب وقتاً أطول من المتوقع، يرجى المحاولة مرة أخرى.',
    );
  }

  factory ApiException.unparseable() {
    return ApiException(
      statusCode: null,
      code: 'INVALID_RESPONSE',
      message: 'تعذر قراءة استجابة الخادم. يرجى المحاولة لاحقاً أو مراجعة مسؤول النظام.',
    );
  }
}
