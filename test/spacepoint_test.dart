import 'package:masar/services/management_service.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:masar/core/constants/app_constants.dart';
import 'package:masar/core/network/api_client.dart';
import 'package:masar/core/network/api_exception.dart';
import 'package:masar/core/storage/secure_storage_service.dart';
import 'package:masar/models/dashboard_model.dart';
import 'package:masar/models/financial_model.dart';
import 'package:masar/models/report_model.dart';
import 'package:masar/models/site_model.dart';
import 'package:masar/models/user_model.dart';
import 'package:masar/models/warehouse_model.dart';
import 'package:masar/models/work_plan_model.dart';
import 'package:masar/services/auth_service.dart';

// مخزن مؤقت للاختبارات
class MockStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveToken(String token) async {
    _data[AppConstants.keyToken] = token;
  }

  @override
  Future<String?> getToken() async => _data[AppConstants.keyToken];

  @override
  Future<void> deleteToken() async {
    _data.remove(AppConstants.keyToken);
  }

  @override
  Future<void> saveUsername(String username) async {
    _data[AppConstants.keyUsername] = username;
  }

  @override
  Future<String?> getUsername() async => _data[AppConstants.keyUsername];

  @override
  Future<void> saveBaseUrl(String url) async {
    _data['base_url'] = url;
  }

  @override
  Future<String> getBaseUrl() async {
    return _data['base_url'] ?? AppConstants.defaultDomain;
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}

// عميل HTTP وهمي للاختبارات
class MockHttpClient extends http.BaseClient {
  final http.Response Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('اختبارات نماذج البيانات (Models JSON Parsing)', () {
    test('تحليل UserModel والتحقق من دور المدير العام', () {
      final jsonAdmin = {
        'id': 1,
        'username': 'admin_omar',
        'full_name': 'عمر الناصري',
        'role': 'admin',
        'is_active': 1,
      };

      final user = UserModel.fromJson(jsonAdmin);
      expect(user.id, 1);
      expect(user.username, 'admin_omar');
      expect(user.isManager, true);
      expect(user.isActive, true);
    });

    test('تحليل DashboardModel مع قائمة متصدري الأداء الهندسي (today_top_engineers)', () {
      final json = {
        'sites': 5,
        'engineers': 12,
        'machinery': 8,
        'pending_reports': 3,
        'inventory_value': 250000.75,
        'today_top_engineers': [
          {
            'engineer_id': 101,
            'full_name': 'م. علي الجبوري',
            'score': 98.5,
            'activity_count': 14,
            'completed_tasks': 5,
          },
          {
            'engineer_id': 102,
            'full_name': 'م. سارة الحمداني',
            'score': 92.0,
            'activity_count': 10,
            'completed_tasks': 4,
          },
        ],
      };

      final dashboard = DashboardModel.fromJson(json);
      expect(dashboard.sitesCount, 5);
      expect(dashboard.engineersCount, 12);
      expect(dashboard.machineryCount, 8);
      expect(dashboard.pendingReportsCount, 3);
      expect(dashboard.inventoryValue, 250000.75);
      expect(dashboard.todayTopEngineers.length, 2);
      expect(dashboard.todayTopEngineers.first.fullName, 'م. علي الجبوري');
      expect(dashboard.todayTopEngineers.first.score, 98.5);
    });

    test('تحليل SiteModel مع الميزانية وأرشفة الإلغاء', () {
      final json = {
        'id': 10,
        'name': 'مشروع برج مكسلوند',
        'client_name': 'شركة الأفق',
        'work_date': '2026-05-01',
        'budget': 3500000.0,
        'status': 'cancelled',
      };

      final site = SiteModel.fromJson(json);
      expect(site.id, 10);
      expect(site.name, 'مشروع برج مكسلوند');
      expect(site.budget, 3500000.0);
      expect(site.isCancelled, true);
    });

    test('تحليل WorkPlanModel وبث التعميم العام', () {
      final json = {
        'id': 20,
        'site_id': 1,
        'title': 'فحص إجراءات السلامة',
        'is_broadcast': 1,
        'priority': 'urgent',
        'status': 'pending',
      };

      final plan = WorkPlanModel.fromJson(json);
      expect(plan.id, 20);
      expect(plan.isBroadcast, true);
      expect(plan.priority, 'urgent');
      expect(plan.isCompleted, false);
    });

    test('تحليل ReportModel مع الإيصالات والمصروفات وحالة الاعتماد', () {
      final json = {
        'id': 500,
        'site_id': 2,
        'report_date': '2026-10-02',
        'workers_count': 15,
        'machinery_count': 3,
        'work_done': 'صب قواعد السرداب',
        'status': 'approved',
        'expenses': [
          {
            'item_name': 'ديزل',
            'quantity': 200,
            'unit_price': 1.5,
          },
        ],
        'receipts': [
          {
            'id': 1,
            'file_url': 'https://example.com/receipt1.jpg',
            'file_name': 'وصل وقود.jpg',
          },
        ],
      };

      final report = ReportModel.fromJson(json);
      expect(report.id, 500);
      expect(report.isApproved, true);
      expect(report.totalExpenses, 300.0);
      expect(report.receipts.length, 1);
      expect(report.receipts.first.fileName, 'وصل وقود.jpg');
    });

    test('تحليل مواد المخزن والحركات المخزنية', () {
      final jsonItem = {
        'id': 1,
        'name': 'إسمنت بورتلاندي',
        'current_stock': 50.0,
        'min_stock': 100.0,
        'unit_price': 6.0,
      };

      final item = WarehouseItemModel.fromJson(jsonItem);
      expect(item.isLowStock, true);
      expect(item.totalValue, 300.0);

      final jsonMove = {
        'id': 1,
        'item_id': 1,
        'move_type': 'out',
        'quantity': 20.0,
      };
      final move = WarehouseMoveModel.fromJson(jsonMove);
      expect(move.moveType, 'out');
      expect(move.quantity, 20.0);
    });

    test('تحليل الحسابات المالية وقيود اليومية المتوازنة', () {
      final jsonAcc = {
        'id': 1010,
        'code': '1010',
        'name': 'الصندوق الرئيسي',
        'type': 'asset',
        'balance': 50000.0,
        'has_journal_entries': 1,
      };

      final acc = AccountModel.fromJson(jsonAcc);
      expect(acc.code, '1010');
      expect(acc.type, 'asset');
      expect(acc.hasJournalEntries, true);

      final jsonEntry = {
        'id': 1,
        'entry_number': 'JV-001',
        'date': '2026-10-02',
        'description': 'صرف عهدة',
        'total_amount': 500.0,
        'lines': [
          {'account_id': 5010, 'debit': 500.0, 'credit': 0.0},
          {'account_id': 1010, 'debit': 0.0, 'credit': 500.0},
        ],
      };

      final entry = JournalEntryModel.fromJson(jsonEntry);
      expect(entry.lines.length, 2);
      expect(entry.lines.first.debit, 500.0);
      expect(entry.lines.last.credit, 500.0);
    });
  });

  group('اختبارات أمان الصلاحيات وحظر غير المدير (Role Enforcement)', () {
    test('قبول دور admin فقط ورفض دور engineer بحظر 403', () async {
      final mockStorage = MockStorageService();

      // خادم وهمي يرجع مهندس (engineer)
      final mockClient = MockHttpClient((request) {
        if (request.url.queryParameters['route'] == 'login') {
          return http.Response(
            jsonEncode({
              'token': 'tok_engineer',
              'user': {
                'id': 102,
                'username': 'eng_ali',
                'full_name': 'م. علي الجبوري',
                'role': 'engineer',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        storageService: mockStorage,
      );

      final authService = AuthService(
        apiClient: apiClient,
        storageService: mockStorage,
      );

      // يجب أن يرمي استثناء 403 لأن الحساب ليس مديراً
      expect(
        () async => await authService.login(
          username: 'eng_ali',
          password: 'Password123!',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );

      // التأكد من عدم تخزين التوكن للحساب المرفوض
      final token = await mockStorage.getToken();
      expect(token, isNull);
    });

    test('تسجيل دخول ناجح للمدير العام (admin)', () async {
      final mockStorage = MockStorageService();

      final mockClient = MockHttpClient((request) {
        if (request.url.queryParameters['route'] == 'login') {
          return http.Response(
            jsonEncode({
              'token': 'tok_admin_valid',
              'user': {
                'id': 1,
                'username': 'admin_maxlond',
                'full_name': 'عمر الناصري',
                'role': 'admin',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        storageService: mockStorage,
      );

      final authService = AuthService(
        apiClient: apiClient,
        storageService: mockStorage,
      );

      final user = await authService.login(
        username: 'admin_maxlond',
        password: 'AdminPassword123!',
      );

      expect(user.role, 'admin');
      expect(user.isManager, true);

      final token = await mockStorage.getToken();
      expect(token, 'tok_admin_valid');
    });
  });

  group('اختبارات معالجة أخطاء HTTP (HTTP Status Handling)', () {
    test('معالجة خطأ 401 انتهاء الجلسة', () async {
      final mockClient = MockHttpClient((request) {
        return http.Response('{"error":"Session expired"}', 401);
      });
      final apiClient = ApiClient(httpClient: mockClient, storageService: MockStorageService());

      expect(
        () => apiClient.get('dashboard'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('معالجة خطأ 404 غير موجود', () async {
      final mockClient = MockHttpClient((request) {
        return http.Response('{"error":"Not found"}', 404);
      });
      final apiClient = ApiClient(httpClient: mockClient, storageService: MockStorageService());

      expect(
        () => apiClient.get('unknown-route'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('معالجة خطأ 409 تعارض البيانات', () async {
      final mockClient = MockHttpClient((request) {
        return http.Response('{"error":"Conflict"}', 409);
      });
      final apiClient = ApiClient(httpClient: mockClient, storageService: MockStorageService());

      expect(
        () => apiClient.post('account-delete', body: {'account_id': 1010}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });

    test('معالجة خطأ 422 خطأ التحقق من المدخلات', () async {
      final mockClient = MockHttpClient((request) {
        return http.Response('{"error":"Validation failed"}', 422);
      });
      final apiClient = ApiClient(httpClient: mockClient, storageService: MockStorageService());

      expect(
        () => apiClient.post('journal-create', body: {'description': 'unbalanced'}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
      );
    });
  });

  group('اختبارات العمليات المالية والمخزنية والإشعارات (Business Logic Validation)', () {
    test('منع الصرف فوق الرصيد المخزني ورمي استثناء 422', () async {
      final mockStorage = MockStorageService();
      final mockClient = MockHttpClient((request) => http.Response(jsonEncode({"success": true}), 200));
 final apiClient = ApiClient(httpClient: mockClient, storageService: mockStorage);
 final mgmtService = ManagementService(apiClient: apiClient);

 final moveData = {
 'item_id': 5,
 'type': 'out',
 'quantity': 50.0,
 'unit_price': 45000.0,
 'site_id': 12,
 };

 expect(
 () => mgmtService.createWarehouseMove(moveData, currentStock: 20.0),
 throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
 );
 });

 test('التحقق من توازن القيد المحاسبي (مجموع المدين = مجموع الدائن)', () async {
 final mockStorage = MockStorageService();
      final mockClient = MockHttpClient((request) => http.Response(jsonEncode({"success": true}), 200));
 final apiClient = ApiClient(httpClient: mockClient, storageService: mockStorage);
 final mgmtService = ManagementService(apiClient: apiClient);

 final unbalancedEntry = {
 'description': 'شراء مواد غير متوازن',
 'site_id': 12,
 'lines': [
 {'account_id': 15, 'debit': 125000.0, 'credit': 0.0},
 {'account_id': 2, 'debit': 0.0, 'credit': 100000.0},
 ],
 };

 expect(
 () => mgmtService.createJournalEntry(unbalancedEntry),
 throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
 );
 });

 test('تحديث حالة الصيانة وتغيير حالة الآلية', () async {
 final mockStorage = MockStorageService();
 Uri? capturedStatusUri;
 String? capturedStatusBody;

 final mockClient = MockHttpClient((request) {
 capturedStatusUri = request.url;
 if (request is http.Request) {
 capturedStatusBody = request.body;
 }
 return http.Response(jsonEncode({'success': true}), 200, headers: {'content-type': 'application/json'});
 });
 final apiClient = ApiClient(httpClient: mockClient, storageService: mockStorage);
 final mgmtService = ManagementService(apiClient: apiClient);

 await mgmtService.setRepairStatus(repairId: 8, status: 'in_progress');
 expect(capturedStatusUri.toString(), contains('route=repair-status'));
 expect(capturedStatusBody, contains('in_progress'));
 });

 test('قراءة الإشعارات الفردية والجماعية', () async {
 final mockStorage = MockStorageService();
 Uri? capturedSingleUri;
 Uri? capturedAllUri;

 final mockClient = MockHttpClient((request) {
 if (request.url.queryParameters['route'] == 'notification-read') {
 capturedSingleUri = request.url;
 return http.Response(jsonEncode({'success': true}), 200, headers: {'content-type': 'application/json'});
 }
 if (request.url.queryParameters['route'] == 'notification-read-all') {
 capturedAllUri = request.url;
 return http.Response(jsonEncode({'success': true}), 200, headers: {'content-type': 'application/json'});
 }
 return http.Response('{}', 404);
 });
 final apiClient = ApiClient(httpClient: mockClient, storageService: mockStorage);
 final mgmtService = ManagementService(apiClient: apiClient);

 await mgmtService.markNotificationRead(3);
 expect(capturedSingleUri.toString(), contains('route=notification-read'));

 await mgmtService.markAllNotificationsRead();
 expect(capturedAllUri.toString(), contains('route=notification-read-all'));
 });
 });
}
