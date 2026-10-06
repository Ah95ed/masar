import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masar/core/api_exception.dart';
import 'package:masar/core/secure_storage.dart';
import 'package:masar/models/user.dart';
import 'package:masar/models/site.dart';
import 'package:masar/models/task.dart';
import 'package:masar/models/report.dart';
import 'package:masar/models/machinery.dart';
import 'package:masar/models/warehouse_item.dart';
import 'package:masar/models/warehouse_move.dart';
import 'package:masar/services/admin_api.dart';
import 'package:masar/services/session_manager.dart';

class MockClientHandler extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;
  MockClientHandler(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    final res = await handler(req);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.instance.init();
  });

  group('Models Serialization Tests', () {
    test('User fromJson and toJson', () {
      final json = {
        'id': 2,
        'full_name': 'Ahmed Admin',
        'username': 'ahmed',
        'email': 'ahmed@test.com',
        'role': 'admin',
        'phone': '0770000000',
        'specialization': 'Management',
        'is_active': 1,
        'approval_status': 'approved',
      };
      final user = User.fromJson(json);
      expect(user.id, 2);
      expect(user.fullName, 'Ahmed Admin');
      expect(user.role, 'admin');
      expect(user.isActive, 1);

      final out = user.toJson();
      expect(out['id'], 2);
      expect(out['username'], 'ahmed');
    });

    test('Site fromJson and toJson', () {
      final json = {
        'id': 10,
        'code': 'S-01',
        'name': 'مشروع البرج',
        'client_name': 'شركة الأمل',
        'work_date': '2026-10-06',
        'start_time': '08:00',
        'end_time': '17:00',
        'location': 'بغداد',
        'budget': 25000000.0,
        'status': 'active',
        'manager_id': 2,
        'description': 'مشروع تجاري',
      };
      final site = Site.fromJson(json);
      expect(site.id, 10);
      expect(site.name, 'مشروع البرج');
      expect(site.budget, 25000000.0);
      expect(site.status, 'active');

      final out = site.toJson();
      expect(out['id'], 10);
      expect(out['name'], 'مشروع البرج');
    });

    test('Task fromJson and toJson', () {
      final json = {
        'id': 5,
        'site_id': 10,
        'site_name': 'مشروع البرج',
        'title': 'صب الأساسات',
        'description': 'صب خرسانة B300',
        'assigned_to': 3,
        'is_broadcast': 0,
        'priority': 'high',
        'status': 'in_progress',
        'progress': 45,
      };
      final task = Task.fromJson(json);
      expect(task.id, 5);
      expect(task.title, 'صب الأساسات');
      expect(task.progress, 45);
      expect(task.isBroadcast, false);

      final out = task.toJson();
      expect(out['id'], 5);
      expect(out['priority'], 'high');
    });

    test('Report fromJson and toJson', () {
      final json = {
        'id': 12,
        'site_id': 10,
        'site_name': 'مشروع البرج',
        'engineer_id': 3,
        'engineer_name': 'مهندس علي',
        'report_date': '2026-10-06',
        'weather': 'مشمس',
        'temperature': 32.5,
        'workers_count': 15,
        'machinery_count': 2,
        'work_done': 'تم إكمال أعمال التسليح',
        'issues': null,
        'materials_used': 'حديد 16 ملم',
        'safety_notes': 'التزام بالخوذ',
        'progress_percent': 60,
        'status': 'submitted',
        'admin_notes': null,
        'expenses': [
          {
            'id': 1,
            'item_name': 'مياه شرب',
            'category': 'ضيافة',
            'quantity': 10,
            'unit_price': 1000,
            'total': 10000,
          }
        ],
        'receipts': [],
      };
      final report = Report.fromJson(json);
      expect(report.id, 12);
      expect(report.workersCount, 15);
      expect(report.expenses.length, 1);
      expect(report.expenses.first.total, 10000.0);
    });

    test('Machinery fromJson and toJson', () {
      final json = {
        'id': 4,
        'code': 'M-04',
        'name': 'حفارة كوماتسو',
        'plate_number': '12345 بغداد',
        'operator_name': 'سالم',
        'status': 'available',
        'hourly_cost': 45000.0,
      };
      final mach = Machinery.fromJson(json);
      expect(mach.id, 4);
      expect(mach.name, 'حفارة كوماتسو');
      expect(mach.hourlyCost, 45000.0);
    });

    test('WarehouseItem fromJson and toJson', () {
      final json = {
        'id': 8,
        'code': 'IT-08',
        'name': 'أسمنت مقاوم',
        'category_id': 2,
        'category_name': 'مواد بناء',
        'unit': 'كيس',
        'quantity': 15.0,
        'min_quantity': 50.0,
        'unit_price': 8000.0,
        'location': 'مستودع A',
        'is_active': 1,
      };
      final item = WarehouseItem.fromJson(json);
      expect(item.id, 8);
      expect(item.isLowStock, true);
    });

    test('WarehouseMove fromJson with signature', () {
      final json = {
        'id': 14,
        'item_id': 8,
        'item_name': 'أسمنت مقاوم',
        'type': 'out',
        'quantity': 20.0,
        'unit': 'كيس',
        'unit_price': 8000.0,
        'total_price': 160000.0,
        'site_id': 10,
        'site_name': 'مشروع البرج',
        'signature_id': 101,
        'signed_by': 'المدير العام',
        'signed_at': '2026-10-06 14:00:00',
      };
      final move = WarehouseMove.fromJson(json);
      expect(move.id, 14);
      expect(move.signedBy, 'المدير العام');
      expect(move.signatureId, 101);
    });
  });

  group('AdminApi Security and WAF Protection Tests', () {
    test('Request headers never include Cookie and include Chrome User-Agent', () async {
      http.Request? capturedRequest;
      final mockClient = MockClientHandler((req) async {
        capturedRequest = req;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'status': 'ok'}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final session = SessionManager.instance;
      await session.setSession('test_token_123', {'id': 2, 'role': 'admin'});

      final api = AdminApi(client: mockClient);
      await api.get('dashboard');

      expect(capturedRequest, isNotNull);
      // WAF rules test: NO cookie allowed
      expect(capturedRequest!.headers.containsKey('Cookie'), false);
      expect(capturedRequest!.headers.containsKey('cookie'), false);
      expect(capturedRequest!.headers['User-Agent'], contains('Chrome/120.0.0.0'));
      expect(capturedRequest!.headers['Authorization'], 'Bearer test_token_123');
    });

    test('Login validates role == admin and rejects non-admin with 403', () async {
      final mockClient = MockClientHandler((req) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'tok_xyz',
              'user': {'id': 7, 'full_name': 'Eng Ali', 'username': 'ali', 'role': 'engineer'}
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = AdminApi(client: mockClient);

      expect(
        () => api.login(username: 'ali', password: 'password123'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('Automatic 401 retry with X-Auth-Token header', () async {
      int attempts = 0;
      final mockClient = MockClientHandler((req) async {
        attempts++;
        if (attempts == 1) {
          expect(req.headers['Authorization'], 'Bearer retry_tok');
          return http.Response(
            '{"error": "Unauthorized"}',
            401,
            headers: {'content-type': 'application/json'},
          );
        } else {
          expect(req.headers['X-Auth-Token'], 'retry_tok');
          return http.Response(
            jsonEncode({'success': true, 'data': {'retried': true}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final session = SessionManager.instance;
      await session.setSession('retry_tok', {'id': 2, 'role': 'admin'});

      final api = AdminApi(client: mockClient);
      final res = await api.get('sites');

      expect(attempts, 2);
      expect(res['retried'], true);
    });
  });
}