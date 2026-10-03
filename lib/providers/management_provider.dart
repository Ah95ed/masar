import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
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
import '../services/management_service.dart';

enum LoadingState { initial, loading, loaded, error }

/// موفر الحالة الشامل لجميع وحدات إدارة مسار للمدير العام (Maxlond Management)
class ManagementProvider extends ChangeNotifier {
  final ManagementService _service;

  ManagementProvider({required ManagementService service}) : _service = service;

  // ==================== لوحة التحكم ====================
  LoadingState dashboardState = LoadingState.initial;
  DashboardModel dashboard = DashboardModel();
  String? dashboardError;

  Future<void> fetchDashboard() async {
    dashboardState = LoadingState.loading;
    dashboardError = null;
    notifyListeners();

    try {
      dashboard = await _service.getDashboard();
      dashboardState = LoadingState.loaded;
    } on ApiException catch (e) {
      dashboardError = e.message;
      dashboardState = LoadingState.error;
    } catch (e) {
      dashboardError = 'تعذر تحميل مؤشرات لوحة التحكم.';
      dashboardState = LoadingState.error;
    }
    notifyListeners();
  }

  // ==================== المواقع الإنشائية ====================
  LoadingState sitesState = LoadingState.initial;
  List<SiteModel> sites = [];
  String? sitesError;

  Future<void> fetchSites() async {
    sitesState = LoadingState.loading;
    sitesError = null;
    notifyListeners();

    try {
      sites = await _service.getSites();
      sitesState = LoadingState.loaded;
    } on ApiException catch (e) {
      sitesError = e.message;
      sitesState = LoadingState.error;
    } catch (e) {
      sitesError = 'تعذر تحميل قائمة مواقع العمل.';
      sitesState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> saveSite(Map<String, dynamic> siteData) async {
    try {
      await _service.saveSite(siteData);
      await fetchSites();
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      sitesError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      sitesError = 'فشل حفظ بيانات الموقع.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSite(int siteId) async {
    try {
      await _service.cancelSite(siteId);
      await fetchSites();
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      sitesError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      sitesError = 'تعذر إلغاء الموقع وأرشفته.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSite(int siteId) async {
    try {
      await _service.deleteSite(siteId);
      await fetchSites();
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      sitesError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      sitesError = 'فشل حذف الموقع.';
      notifyListeners();
      return false;
    }
  }

  // ==================== خطط العمل والمهام ====================
  LoadingState workPlansState = LoadingState.initial;
  List<WorkPlanModel> workPlans = [];
  String? workPlansError;
  int? selectedPlanSiteId;
  String selectedPlanStatus = 'all';

  Future<void> fetchWorkPlans({int? siteId, String? status}) async {
    workPlansState = LoadingState.loading;
    workPlansError = null;
    selectedPlanSiteId = siteId;
    if (status != null) selectedPlanStatus = status;
    notifyListeners();

    try {
      workPlans = await _service.getTasks(
        siteId: selectedPlanSiteId,
        status: selectedPlanStatus == 'all' ? null : selectedPlanStatus,
      );
      workPlansState = LoadingState.loaded;
    } on ApiException catch (e) {
      workPlansError = e.message;
      workPlansState = LoadingState.error;
    } catch (e) {
      workPlansError = 'تعذر تحميل خطط العمل.';
      workPlansState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> saveWorkPlan(Map<String, dynamic> planData) async {
    try {
      await _service.saveWorkPlan(planData);
      await fetchWorkPlans(siteId: selectedPlanSiteId, status: selectedPlanStatus);
      return true;
    } on ApiException catch (e) {
      workPlansError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      workPlansError = 'فشل حفظ خطة العمل.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelWorkPlan(int taskId) async {
    try {
      await _service.cancelWorkPlan(taskId);
      await fetchWorkPlans(siteId: selectedPlanSiteId, status: selectedPlanStatus);
      return true;
    } on ApiException catch (e) {
      workPlansError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      workPlansError = 'تعذر إلغاء خطة العمل.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorkPlan(int taskId) async {
    try {
      await _service.deleteWorkPlan(taskId);
      await fetchWorkPlans(siteId: selectedPlanSiteId, status: selectedPlanStatus);
      return true;
    } on ApiException catch (e) {
      workPlansError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      workPlansError = 'فشل حذف خطة العمل.';
      notifyListeners();
      return false;
    }
  }

  // ==================== مراجعة واعتماد التقارير ====================
  LoadingState reportsState = LoadingState.initial;
  List<ReportModel> reports = [];
  String? reportsError;
  String selectedReportStatus = 'all';
  int? selectedReportSiteId;

  Future<void> fetchReports({String? status, int? siteId}) async {
    reportsState = LoadingState.loading;
    reportsError = null;
    if (status != null) selectedReportStatus = status;
    selectedReportSiteId = siteId;
    notifyListeners();

    try {
      reports = await _service.getReports(
        status: selectedReportStatus == 'all' ? null : selectedReportStatus,
        siteId: selectedReportSiteId,
      );
      reportsState = LoadingState.loaded;
    } on ApiException catch (e) {
      reportsError = e.message;
      reportsState = LoadingState.error;
    } catch (e) {
      reportsError = 'تعذر تحميل التقارير اليومية.';
      reportsState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<ReportModel?> getReportDetails(int reportId) async {
    try {
      return await _service.getReportDetails(reportId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> reviewReport({
    required int reportId,
    required String decision,
    String? adminNotes,
  }) async {
    try {
      await _service.reviewReport(
        reportId: reportId,
        decision: decision,
        adminNotes: adminNotes,
      );
      await fetchReports(status: selectedReportStatus, siteId: selectedReportSiteId);
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      reportsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      reportsError = 'فشل مراجعة التقرير.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReport(Map<String, dynamic> data) async {
    try {
      await _service.updateReport(data);
      await fetchReports(status: selectedReportStatus, siteId: selectedReportSiteId);
      return true;
    } on ApiException catch (e) {
      reportsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      reportsError = 'فشل تعديل بيانات التقرير.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReport(int reportId) async {
    try {
      await _service.deleteReport(reportId);
      await fetchReports(status: selectedReportStatus, siteId: selectedReportSiteId);
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      reportsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      reportsError = 'فشل حذف التقرير.';
      notifyListeners();
      return false;
    }
  }

  // ==================== إدارة المستخدمين ====================
  LoadingState usersState = LoadingState.initial;
  List<UserModel> users = [];
  String? usersError;

  Future<void> fetchUsers() async {
    usersState = LoadingState.loading;
    usersError = null;
    notifyListeners();

    try {
      users = await _service.getUsers();
      usersState = LoadingState.loaded;
    } on ApiException catch (e) {
      usersError = e.message;
      usersState = LoadingState.error;
    } catch (e) {
      usersError = 'تعذر تحميل قائمة المستخدمين.';
      usersState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> saveUser(Map<String, dynamic> userData) async {
    try {
      await _service.saveUser(userData);
      await fetchUsers();
      return true;
    } on ApiException catch (e) {
      usersError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      usersError = 'فشل حفظ بيانات المستخدم.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setUserStatus(int userId, String status) async {
    try {
      await _service.setUserStatus(userId: userId, status: status);
      await fetchUsers();
      return true;
    } on ApiException catch (e) {
      usersError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      usersError = 'فشل تغيير حالة المستخدم.';
      notifyListeners();
      return false;
    }
  }

  // ==================== الآليات والمعدات ====================
  LoadingState machineryState = LoadingState.initial;
  List<MachineryModel> machinery = [];
  String? machineryError;

  Future<void> fetchMachinery() async {
    machineryState = LoadingState.loading;
    machineryError = null;
    notifyListeners();

    try {
      machinery = await _service.getMachinery();
      machineryState = LoadingState.loaded;
    } on ApiException catch (e) {
      machineryError = e.message;
      machineryState = LoadingState.error;
    } catch (e) {
      machineryError = 'تعذر تحميل الآليات.';
      machineryState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> saveMachinery(Map<String, dynamic> data) async {
    try {
      await _service.saveMachinery(data);
      await fetchMachinery();
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      machineryError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      machineryError = 'فشل حفظ بيانات الآلية.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setMachineryStatus(int machineryId, String status) async {
    try {
      await _service.setMachineryStatus(machineryId: machineryId, status: status);
      await fetchMachinery();
      return true;
    } on ApiException catch (e) {
      machineryError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      machineryError = 'تعذر تحديث حالة الآلية.';
      notifyListeners();
      return false;
    }
  }

  // ==================== الصيانة والإصلاح ====================
  LoadingState repairsState = LoadingState.initial;
  List<RepairModel> repairs = [];
  String? repairsError;

  Future<void> fetchRepairs() async {
    repairsState = LoadingState.loading;
    repairsError = null;
    notifyListeners();

    try {
      repairs = await _service.getRepairs();
      repairsState = LoadingState.loaded;
    } on ApiException catch (e) {
      repairsError = e.message;
      repairsState = LoadingState.error;
    } catch (e) {
      repairsError = 'تعذر تحميل سجلات الصيانة.';
      repairsState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> createRepair(Map<String, dynamic> data) async {
    try {
      await _service.createRepair(data);
      await fetchRepairs();
      return true;
    } on ApiException catch (e) {
      repairsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      repairsError = 'فشل تسجيل أمر الصيانة.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRepair(Map<String, dynamic> data) async {
    try {
      await _service.updateRepair(data);
      await fetchRepairs();
      return true;
    } on ApiException catch (e) {
      repairsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      repairsError = 'فشل تحديث أمر الصيانة.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setRepairStatus(int repairId, String status) async {
    try {
      await _service.setRepairStatus(repairId: repairId, status: status);
      await fetchRepairs();
      return true;
    } on ApiException catch (e) {
      repairsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      repairsError = 'تعذر تحديث حالة الصيانة.';
      notifyListeners();
      return false;
    }
  }

  // ==================== المستودع والمخزن ====================
  LoadingState warehouseState = LoadingState.initial;
  List<WarehouseItemModel> warehouseItems = [];
  List<WarehouseCategoryModel> warehouseCategories = [];
  List<WarehouseMoveModel> warehouseMoves = [];
  String? warehouseError;

  Future<void> fetchWarehouseData() async {
    warehouseState = LoadingState.loading;
    warehouseError = null;
    notifyListeners();

    try {
      warehouseItems = await _service.getWarehouseItems();
      warehouseCategories = await _service.getWarehouseCategories();
      warehouseMoves = await _service.getWarehouseMoves();
      warehouseState = LoadingState.loaded;
    } on ApiException catch (e) {
      warehouseError = e.message;
      warehouseState = LoadingState.error;
    } catch (e) {
      warehouseError = 'تعذر تحميل بيانات المستودع والمخزون.';
      warehouseState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> saveWarehouseItem(Map<String, dynamic> data) async {
    try {
      await _service.saveWarehouseItem(data);
      await fetchWarehouseData();
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      warehouseError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      warehouseError = 'فشل حفظ الصنف المخزني.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveWarehouseCategory(Map<String, dynamic> data) async {
    try {
      await _service.saveWarehouseCategory(data);
      await fetchWarehouseData();
      return true;
    } on ApiException catch (e) {
      warehouseError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      warehouseError = 'فشل حفظ الفئة المخزنية.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setWarehouseItemStatus(int itemId, String status) async {
    try {
      await _service.setWarehouseItemStatus(itemId: itemId, status: status);
      await fetchWarehouseData();
      return true;
    } on ApiException catch (e) {
      warehouseError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      warehouseError = 'تعذر تحديث حالة الصنف.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createWarehouseMove(Map<String, dynamic> data) async {
    try {
      await _service.createWarehouseMove(data);
      await fetchWarehouseData();
      await fetchDashboard();
      return true;
    } on ApiException catch (e) {
      warehouseError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      warehouseError = 'فشل تسجيل الحركة المخزنية.';
      notifyListeners();
      return false;
    }
  }

  // ==================== الحسابات والمالية ====================
  LoadingState financialState = LoadingState.initial;
  List<AccountModel> accounts = [];
  List<JournalEntryModel> journalEntries = [];
  FinancialSummaryModel financialSummary = FinancialSummaryModel();
  String? financialError;

  Future<void> fetchFinancialData() async {
    financialState = LoadingState.loading;
    financialError = null;
    notifyListeners();

    try {
      accounts = await _service.getAccounts();
      journalEntries = await _service.getJournalEntries();
      financialSummary = await _service.getFinancialSummary();
      financialState = LoadingState.loaded;
    } on ApiException catch (e) {
      financialError = e.message;
      financialState = LoadingState.error;
    } catch (e) {
      financialError = 'تعذر تحميل البيانات المالية والحسابات.';
      financialState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<bool> saveAccount(Map<String, dynamic> data) async {
    try {
      await _service.saveAccount(data);
      await fetchFinancialData();
      return true;
    } on ApiException catch (e) {
      financialError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      financialError = 'فشل حفظ بيانات الحساب.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(int accountId) async {
    try {
      await _service.deleteAccount(accountId);
      await fetchFinancialData();
      return true;
    } on ApiException catch (e) {
      financialError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      financialError = 'تعذر حذف الحساب.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createJournalEntry(Map<String, dynamic> data) async {
    try {
      await _service.createJournalEntry(data);
      await fetchFinancialData();
      return true;
    } on ApiException catch (e) {
      financialError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      financialError = 'فشل ترحيل قيد اليومية.';
      notifyListeners();
      return false;
    }
  }

  // ==================== الإشعارات ====================
  LoadingState notificationsState = LoadingState.initial;
  List<NotificationModel> notifications = [];
  String? notificationsError;

  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    notificationsState = LoadingState.loading;
    notificationsError = null;
    notifyListeners();

    try {
      notifications = await _service.getNotifications();
      notificationsState = LoadingState.loaded;
    } on ApiException catch (e) {
      notificationsError = e.message;
      notificationsState = LoadingState.error;
    } catch (e) {
      notificationsError = 'تعذر تحميل الإشعارات.';
      notificationsState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<void> markNotificationRead(int notificationId) async {
    try {
      await _service.markNotificationRead(notificationId);
      final idx = notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        notifications[idx] = NotificationModel(
          id: notifications[idx].id,
          title: notifications[idx].title,
          message: notifications[idx].message,
          isRead: true,
          createdAt: notifications[idx].createdAt,
          type: notifications[idx].type,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _service.markAllNotificationsRead();
      notifications = notifications
          .map((n) => NotificationModel(
                id: n.id,
                title: n.title,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
                type: n.type,
              ))
          .toList();
      notifyListeners();
    } catch (_) {}
  }
}
