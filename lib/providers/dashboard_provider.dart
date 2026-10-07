import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../services/admin_api.dart';

/// موفر حالة لوحة التحكم الرئيسية ومؤشرات الأداء
class DashboardProvider extends ChangeNotifier {
  final AdminApi api;

  DashboardProvider({AdminApi? api}) : api = api ?? AdminApi();

  Map<String, dynamic>? _data;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic> get stats => (_data?['stats'] as Map<String, dynamic>?) ?? {};

  String get totalSites => stats['total_sites']?.toString() ?? _data?['sites']?.toString() ?? '0';
  String get activeSites => stats['active_sites']?.toString() ?? _data?['sites']?.toString() ?? '0';
  String get pendingReports => stats['pending_reports']?.toString() ?? _data?['pending_reports']?.toString() ?? '0';
  String get activeTasks => stats['active_tasks']?.toString() ?? '0';
  String get totalMachinery => stats['total_machinery']?.toString() ?? _data?['machinery']?.toString() ?? '0';
  String get lowStockItems => stats['low_stock_items']?.toString() ?? '0';

  int get sitesCount => int.tryParse(totalSites) ?? 0;
  int get activeSitesCount => int.tryParse(activeSites) ?? 0;
  int get engineersCount => int.tryParse(_data?['engineers']?.toString() ?? stats['total_engineers']?.toString() ?? '0') ?? 0;
  int get machineryCount => int.tryParse(totalMachinery) ?? 0;
  int get pendingReportsCount => int.tryParse(pendingReports) ?? 0;

  List<dynamic> get topEngineers => (_data?['top_engineers'] as List?) ?? (_data?['today_top_engineers'] as List?) ?? [];
  List<dynamic> get todayTopEngineers => (_data?['today_top_engineers'] as List?) ?? (_data?['top_engineers'] as List?) ?? [];

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('dashboard');
      if (res is Map<String, dynamic>) {
        _data = res;
      } else if (res is Map) {
        _data = Map<String, dynamic>.from(res);
      } else {
        _data = {};
      }
      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تحميل لوحة التحكم';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<void> refreshSilently() async {
    try {
      final res = await api.get('dashboard');
      if (res is Map<String, dynamic>) {
        _data = res;
      } else if (res is Map) {
        _data = Map<String, dynamic>.from(res);
      }
      notifyListeners();
    } catch (_) {}
  }
}