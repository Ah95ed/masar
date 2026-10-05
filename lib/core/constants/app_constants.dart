/// ثوابت وتكوينات نظام Maxlond Management (إدارة مسار) - خاص بالإدارة والمدير
class AppConstants {
  AppConstants._();

  // اسم التطبيق
  static const String appName = 'Maxlond Management';
  static const String appArabicName = 'إدارة مسار - Maxlond';
  static const String appSubtitle = 'منظومة الإدارة العليا والرقابة الميدانية والمشاريع';

  // النطاق الافتراضي
  // النطاق الأساسي الرسمي للنظام
  static const String defaultDomain = 'https://aksat.shop';

  // روابط الـ API الأساسية المعتمدة رسمياً
  // مصادقة المستخدمين: https://aksat.shop/api/auth.php?route=
  // عمليات المدير: https://aksat.shop/api/management.php?route=
  static const String authBaseUrl = 'https://aksat.shop/api/auth.php?route=';
  static const String managementBaseUrl = 'https://aksat.shop/api/management.php?route=';

  // مسارات Base URLs
  // https://DOMAIN/api/auth.php?route=
  // https://DOMAIN/api/management.php?route=
  static String buildAuthUrl(String domain) {
    final clean = domain.trim().replaceAll(RegExp(r'/+$'), '');
    return '$clean/api/auth.php?route=';
  }

  static String buildManagementUrl(String domain) {
    final clean = domain.trim().replaceAll(RegExp(r'/+$'), '');
    return '$clean/api/management.php?route=';
  }

  // مفاتيح التخزين الآمن
  static const String keyToken = 'maxlond_admin_token';
  static const String keyDomain = 'maxlond_domain';
  static const String keyUsername = 'maxlond_saved_username';

  // تعريف الجهاز لطلب الدخول
  static const String deviceInfo = 'Maxlond Management';
  static const String defaultDeviceInfo = deviceInfo;
  static const String defaultBaseUrl = defaultDomain;

  // الدور المطلوب حصراً
  static const String requiredRole = 'admin';

  // مسارات Auth
  static const String routeLogin = 'login';
  static const String routeLogout = 'logout';
  static const String routeMe = 'me';

  // مسارات Management
  static const String routeDashboard = 'dashboard';

  // المواقع
  static const String routeSites = 'sites';
  static const String routeSiteSave = 'site-save';
  static const String routeSiteCancel = 'site-cancel';
  static const String routeSiteDelete = 'site-delete';

  // خطط العمل والمهام
  static const String routeTasks = 'tasks';
  static const String routeWorkPlanSave = 'work-plan-save';
  static const String routeWorkPlanCancel = 'work-plan-cancel';
  static const String routeWorkPlanDelete = 'work-plan-delete';

  // التقارير والمراجعة
  static const String routeReports = 'reports';
  static const String routeReportReview = 'report-review';
  static const String routeReportUpdate = 'report-update';
  static const String routeReportDelete = 'report-delete';

  // المستخدمون
  static const String routeUsers = 'users';
  static const String routeUserSave = 'user-save';
  static const String routeUserStatus = 'user-status';

  // الآليات
  static const String routeMachinery = 'machinery';
  static const String routeMachinerySave = 'machinery-save';
  static const String routeMachineryStatus = 'machinery-status';

  // المخزن
  static const String routeWarehouseItems = 'warehouse-items';
  static const String routeWarehouseCategories = 'warehouse-categories';
  static const String routeWarehouseMoves = 'warehouse-moves';
  static const String routeWarehouseItemSave = 'warehouse-item-save';
  static const String routeWarehouseCategorySave = 'warehouse-category-save';
  static const String routeWarehouseItemStatus = 'warehouse-item-status';
  static const String routeWarehouseMoveCreate = 'warehouse-move-create';

  // الصيانة
  static const String routeRepairs = 'repairs';
  static const String routeRepairCreate = 'repair-create';
  static const String routeRepairUpdate = 'repair-update';
  static const String routeRepairStatus = 'repair-status';

  // المالية والحسابات
  static const String routeAccounts = 'accounts';
  static const String routeAccountSave = 'account-save';
  static const String routeAccountDelete = 'account-delete';
  static const String routeJournal = 'journal';
  static const String routeJournalEntry = 'journal-entry';
  static const String routeJournalCreate = 'journal-create';
  static const String routeFinancial = 'financial';

  // الإشعارات
  static const String routeNotifications = 'notifications';
  static const String routeNotificationRead = 'notification-read';
  static const String routeNotificationReadAll = 'notification-read-all';

  // أدوار المستخدمين المتاحة للإنشاء من قبل الإدارة
  static const List<String> creatableRoles = [
    'engineer',
    'accountant',
    'admin',
  ];

  // أولويات العمل
  static const List<String> priorityList = [
    'low',
    'medium',
    'high',
    'urgent',
  ];

  // أنواع الحسابات المالية
  static const List<String> accountTypes = [
    'asset', // أصول
    'liability', // خصوم
    'equity', // حقوق ملكية
    'revenue', // إيرادات
    'expense', // مصروفات
  ];
}
