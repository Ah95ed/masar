import 'package:flutter_test/flutter_test.dart';
import 'package:masar/providers/dashboard_provider.dart';
import 'package:masar/providers/sites_provider.dart';
import 'package:masar/providers/tasks_provider.dart';
import 'package:masar/providers/reports_provider.dart';
import 'package:masar/providers/warehouse_provider.dart';
import 'package:masar/providers/users_provider.dart';
import 'package:masar/providers/notifications_provider.dart';
import 'package:masar/services/admin_api.dart';

class MockAdminApi extends AdminApi {
  @override
  Future<dynamic> get(String route, [Map<String, String> q = const {}]) async {
    if (route == 'dashboard') {
      return {
        'stats': {
          'total_sites': 5,
          'active_sites': 3,
          'pending_reports': 2,
          'active_tasks': 4,
          'total_machinery': 10,
          'low_stock_items': 1,
        },
        'top_engineers': [
          {'engineer_name': 'Ali', 'reports_count': 15}
        ]
      };
    }
    if (route == 'sites') {
      return [
        {'id': 1, 'code': 'S-01', 'name': 'موقع النخيل', 'client_name': 'شركة أ', 'status': 'active', 'budget': 50000}
      ];
    }
    if (route == 'tasks') {
      return [
        {'id': 10, 'site_id': 1, 'title': 'صب الأساسات', 'status': 'in_progress', 'progress': 60}
      ];
    }
    if (route == 'reports') {
      return [
        {'id': 100, 'site_id': 1, 'engineer_id': 2, 'report_date': '2026-10-07', 'work_done': 'أعمال حفر', 'status': 'submitted'}
      ];
    }
    if (route == 'warehouse-moves') {
      return [
        {'id': 50, 'item_id': 5, 'item_name': 'حديد تسليح', 'type': 'in', 'quantity': 20, 'signed_by': 'المدير'}
      ];
    }
    if (route == 'users') {
      return [
        {'id': 2, 'full_name': 'Ahmed', 'username': 'ahmed', 'email': 'ahmed@test.com', 'role': 'admin', 'is_active': 1}
      ];
    }
    if (route == 'notifications') {
      return [
        {'id': 1, 'title': 'تقرير جديد', 'message': 'تم رفع تقرير', 'is_read': 0}
      ];
    }
    return [];
  }

  @override
  Future<dynamic> post(String route, Map<String, dynamic> body) async {
    return {'success': true};
  }
}

void main() {
  group('Domain Providers Architecture Tests', () {
    late MockAdminApi mockApi;

    setUp(() {
      mockApi = MockAdminApi();
    });

    test('DashboardProvider fetches and parses stats correctly', () async {
      final p = DashboardProvider(api: mockApi);
      expect(p.isLoading, isFalse);
      await p.fetchDashboard();
      expect(p.totalSites, '5');
      expect(p.activeSites, '3');
      expect(p.pendingReports, '2');
      expect(p.topEngineers.length, 1);
    });

    test('SitesProvider fetches and filters sites', () async {
      final p = SitesProvider(api: mockApi);
      await p.fetchSites();
      expect(p.sites.length, 1);
      expect(p.filteredSites.first.name, 'موقع النخيل');

      p.setSearch('غير موجود');
      expect(p.filteredSites.isEmpty, isTrue);

      p.setSearch('');
      expect(p.filteredSites.length, 1);
    });

    test('TasksProvider tracks progress and task counts', () async {
      final p = TasksProvider(api: mockApi);
      await p.fetchTasks();
      expect(p.tasks.length, 1);
      expect(p.inProgressCount, 1);
      expect(p.avgProgress, 60);
    });

    test('ReportsProvider fetches reports and counts pending status', () async {
      final p = ReportsProvider(api: mockApi);
      await p.fetchReports();
      expect(p.reports.length, 1);
      expect(p.pendingCount, 1);
    });

    test('WarehouseProvider tracks moves and signed status', () async {
      final p = WarehouseProvider(api: mockApi);
      await p.fetchMoves();
      expect(p.moves.length, 1);
      expect(p.signedMovesCount, 1);
      expect(p.unsignedMovesCount, 0);
    });

    test('UsersProvider parses users and supports search & filter', () async {
      final p = UsersProvider(api: mockApi);
      await p.fetchUsers();
      expect(p.users.length, 1);
      expect(p.filteredUsers.first.username, 'ahmed');

      final user = p.users.first;
      final toggleSuccess = await p.toggleUserStatus(user);
      expect(toggleSuccess, isTrue);
    });

    test('NotificationsProvider manages unread badge and markRead', () async {
      final p = NotificationsProvider(api: mockApi);
      await p.fetchNotifications();
      expect(p.notifications.length, 1);
      expect(p.unreadCount, 1);

      final readSuccess = await p.markRead(1);
      expect(readSuccess, isTrue);
      expect(p.unreadCount, 0);
    });
  });
}
