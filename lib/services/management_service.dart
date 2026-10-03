import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../models/site_model.dart';
import '../models/work_plan_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../models/machinery_model.dart';
import '../models/warehouse_model.dart';
import '../models/repair_model.dart';
import '../models/financial_model.dart';
import '../models/notification_model.dart';

/// الخدمة المركزية لإدارة عمليات المدير العام (Maxlond Management)
class ManagementService {
  final ApiClient apiClient;

  ManagementService({required this.apiClient});

  // ==================== لوحة التحكم ====================
  Future<DashboardModel> getDashboard() async {
    final response = await apiClient.get(AppConstants.routeDashboard);
    if (response is Map<String, dynamic>) {
      return DashboardModel.fromJson(response);
    }
    return DashboardModel();
  }

  // ==================== المواقع والمشاريع ====================
  Future<List<SiteModel>> getSites() async {
    final response = await apiClient.get(AppConstants.routeSites);
    if (response is List) {
      return response
          .map((item) => SiteModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> saveSite(Map<String, dynamic> siteData) async {
    await apiClient.post(AppConstants.routeSiteSave, body: siteData);
  }

  Future<void> cancelSite(int siteId) async {
    await apiClient.post(
      AppConstants.routeSiteCancel,
      body: {'site_id': siteId},
    );
  }

  Future<void> deleteSite(int siteId) async {
    await apiClient.post(
      AppConstants.routeSiteDelete,
      body: {'site_id': siteId},
    );
  }

  // ==================== خطط العمل والمهام ====================
  Future<List<WorkPlanModel>> getTasks({int? siteId, String? status}) async {
    final queryParams = <String, String>{};
    if (siteId != null) queryParams['site_id'] = siteId.toString();
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final response = await apiClient.get(
      AppConstants.routeTasks,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => WorkPlanModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> saveWorkPlan(Map<String, dynamic> planData) async {
    await apiClient.post(AppConstants.routeWorkPlanSave, body: planData);
  }

  Future<void> cancelWorkPlan(int taskId) async {
    await apiClient.post(
      AppConstants.routeWorkPlanCancel,
      body: {'task_id': taskId},
    );
  }

  Future<void> deleteWorkPlan(int taskId) async {
    await apiClient.post(
      AppConstants.routeWorkPlanDelete,
      body: {'task_id': taskId},
    );
  }

  // ==================== التقارير والمراجعة ====================
  Future<List<ReportModel>> getReports({String? status, int? siteId}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (siteId != null) queryParams['site_id'] = siteId.toString();

    final response = await apiClient.get(
      AppConstants.routeReports,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => ReportModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<ReportModel> getReportDetails(int reportId) async {
    final response = await apiClient.get(
      AppConstants.routeReports,
      queryParams: {'id': reportId.toString()},
    );

    if (response is Map<String, dynamic>) {
      return ReportModel.fromJson(response);
    }
    throw Exception('تعذر جلب تفاصيل التقرير');
  }

  Future<void> reviewReport({
    required int reportId,
    required String decision,
    String? adminNotes,
  }) async {
    await apiClient.post(
      AppConstants.routeReportReview,
      body: {
        'report_id': reportId,
        'decision': decision,
        'admin_notes': ?adminNotes,
      },
    );
  }

  Future<void> updateReport(Map<String, dynamic> reportData) async {
    await apiClient.post(AppConstants.routeReportUpdate, body: reportData);
  }

  Future<void> deleteReport(int reportId) async {
    await apiClient.post(
      AppConstants.routeReportDelete,
      body: {'report_id': reportId},
    );
  }

  // ==================== المستخدمين والكادر ====================
  Future<List<UserModel>> getUsers() async {
    final response = await apiClient.get(AppConstants.routeUsers);
    if (response is List) {
      return response
          .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    await apiClient.post(AppConstants.routeUserSave, body: userData);
  }

  Future<void> setUserStatus({required int userId, required String status}) async {
    await apiClient.post(
      AppConstants.routeUserStatus,
      body: {
        'user_id': userId,
        'status': status,
      },
    );
  }

  // ==================== الآليات والمعدات ====================
  Future<List<MachineryModel>> getMachinery() async {
    final response = await apiClient.get(AppConstants.routeMachinery);
    if (response is List) {
      return response
          .map((item) => MachineryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> saveMachinery(Map<String, dynamic> machineryData) async {
    await apiClient.post(AppConstants.routeMachinerySave, body: machineryData);
  }

  Future<void> setMachineryStatus({required int machineryId, required String status}) async {
    await apiClient.post(
      AppConstants.routeMachineryStatus,
      body: {
        'machinery_id': machineryId,
        'status': status,
      },
    );
  }

  // ==================== المستودع والمخزن ====================
  Future<List<WarehouseItemModel>> getWarehouseItems() async {
    final response = await apiClient.get(AppConstants.routeWarehouseItems);
    if (response is List) {
      return response
          .map((item) => WarehouseItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<List<WarehouseCategoryModel>> getWarehouseCategories() async {
    final response = await apiClient.get(AppConstants.routeWarehouseCategories);
    if (response is List) {
      return response
          .map((item) => WarehouseCategoryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<List<WarehouseMoveModel>> getWarehouseMoves() async {
    final response = await apiClient.get(AppConstants.routeWarehouseMoves);
    if (response is List) {
      return response
          .map((item) => WarehouseMoveModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> saveWarehouseItem(Map<String, dynamic> itemData) async {
    await apiClient.post(AppConstants.routeWarehouseItemSave, body: itemData);
  }

  Future<void> saveWarehouseCategory(Map<String, dynamic> catData) async {
    await apiClient.post(AppConstants.routeWarehouseCategorySave, body: catData);
  }

  Future<void> setWarehouseItemStatus({required int itemId, required String status}) async {
    await apiClient.post(
      AppConstants.routeWarehouseItemStatus,
      body: {
        'item_id': itemId,
        'status': status,
      },
    );
  }

  Future<void> createWarehouseMove(Map<String, dynamic> moveData) async {
    await apiClient.post(AppConstants.routeWarehouseMoveCreate, body: moveData);
  }

  // ==================== الصيانة والإصلاح ====================
  Future<List<RepairModel>> getRepairs() async {
    final response = await apiClient.get(AppConstants.routeRepairs);
    if (response is List) {
      return response
          .map((item) => RepairModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<RepairModel> getRepairDetails(int repairId) async {
    final response = await apiClient.get(
      AppConstants.routeRepairs,
      queryParams: {'id': repairId.toString()},
    );
    if (response is Map<String, dynamic>) {
      return RepairModel.fromJson(response);
    }
    throw Exception('تعذر جلب تفاصيل أمر الصيانة');
  }

  Future<void> createRepair(Map<String, dynamic> repairData) async {
    await apiClient.post(AppConstants.routeRepairCreate, body: repairData);
  }

  Future<void> updateRepair(Map<String, dynamic> repairData) async {
    await apiClient.post(AppConstants.routeRepairUpdate, body: repairData);
  }

  Future<void> setRepairStatus({required int repairId, required String status}) async {
    await apiClient.post(
      AppConstants.routeRepairStatus,
      body: {
        'repair_id': repairId,
        'status': status,
      },
    );
  }

  // ==================== الحسابات والمالية ====================
  Future<List<AccountModel>> getAccounts() async {
    final response = await apiClient.get(AppConstants.routeAccounts);
    if (response is List) {
      return response
          .map((item) => AccountModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<List<JournalEntryModel>> getJournalEntries() async {
    final response = await apiClient.get(AppConstants.routeJournal);
    if (response is List) {
      return response
          .map((item) => JournalEntryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<JournalEntryModel> getJournalEntryDetails(int entryId) async {
    final response = await apiClient.get(
      'journal-entry',
      queryParams: {'id': entryId.toString()},
    );
    if (response is Map<String, dynamic>) {
      return JournalEntryModel.fromJson(response);
    }
    throw Exception('تعذر جلب تفاصيل قيد اليومية');
  }

  Future<FinancialSummaryModel> getFinancialSummary() async {
    final response = await apiClient.get(AppConstants.routeFinancial);
    if (response is Map<String, dynamic>) {
      return FinancialSummaryModel.fromJson(response);
    }
    return FinancialSummaryModel();
  }

  Future<void> saveAccount(Map<String, dynamic> accountData) async {
    await apiClient.post(AppConstants.routeAccountSave, body: accountData);
  }

  Future<void> deleteAccount(int accountId) async {
    await apiClient.post(
      AppConstants.routeAccountDelete,
      body: {'account_id': accountId},
    );
  }

  Future<void> createJournalEntry(Map<String, dynamic> entryData) async {
    await apiClient.post(AppConstants.routeJournalCreate, body: entryData);
  }

  // ==================== الإشعارات ====================
  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.get(AppConstants.routeNotifications);
    if (response is List) {
      return response
          .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> markNotificationRead(int notificationId) async {
    await apiClient.post(
      AppConstants.routeNotificationRead,
      body: {'notification_id': notificationId},
    );
  }

  Future<void> markAllNotificationsRead() async {
    await apiClient.post(AppConstants.routeNotificationReadAll);
  }
}
