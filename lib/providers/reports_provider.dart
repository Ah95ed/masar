import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/report.dart';
import '../services/admin_api.dart';

/// موفر حالة مراجعة واعتماد التقارير الميدانية والمصروفات
class ReportsProvider extends ChangeNotifier {
  final AdminApi api;

  ReportsProvider({AdminApi? api}) : api = api ?? AdminApi();

  List<Report> _reports = [];
  Report? _selectedReport;
  bool _isLoading = false;
  String? _error;
  String _filterStatus = 'all';

  List<Report> get reports => _reports;
  Report? get selectedReport => _selectedReport;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;

  int get pendingCount => _reports.where((r) => r.isSubmitted).length;
  int get approvedCount => _reports.where((r) => r.isApproved).length;
  int get rejectedCount => _reports.where((r) => r.isRejected).length;

  List<Report> get filteredReports {
    if (_filterStatus == 'all') return _reports;
    return _reports.where((r) => r.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('reports');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['reports'] ?? res['data'] ?? res['items'] ?? [];
      }
      _reports = rawList
          .whereType<Map>()
          .map((e) => Report.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تحميل التقارير';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<Report?> fetchReportDetails(int id) async {
    try {
      final res = await api.get('reports', {'id': id.toString()});
      if (res is Map<String, dynamic>) {
        _selectedReport = Report.fromJson(res);
      } else if (res is Map) {
        _selectedReport = Report.fromJson(Map<String, dynamic>.from(res));
      }
      notifyListeners();
      return _selectedReport;
    } catch (_) {
      return null;
    }
  }

  Future<bool> reviewReport({
    required int reportId,
    required String decision,
    String? adminNotes,
  }) async {
    try {
      await api.post('report-review', {
        'report_id': reportId,
        'decision': decision,
        'admin_notes': adminNotes ?? '',
      });
      await fetchReports();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل اعتماد/رفض التقرير';
      notifyListeners();
      return false;
    }
  }
}
