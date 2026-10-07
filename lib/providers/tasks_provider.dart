import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/task.dart';
import '../services/admin_api.dart';

/// موفر حالة خطط العمل والمهام وتحديثات المهندسين
class TasksProvider extends ChangeNotifier {
  final AdminApi api;

  TasksProvider({AdminApi? api}) : api = api ?? AdminApi();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String _filterStatus = 'all';
  String _searchQuery = '';

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  int get inProgressCount => _tasks.where((t) => t.status.toLowerCase() == 'in_progress').length;
  int get doneCount => _tasks.where((t) => t.status.toLowerCase() == 'done' || t.status.toLowerCase() == 'completed').length;
  int get reviewCount => _tasks.where((t) => t.status.toLowerCase() == 'review').length;
  int get avgProgress => _tasks.isEmpty
      ? 0
      : (_tasks.fold<int>(0, (acc, t) => acc + t.progress) / _tasks.length).round();

  List<Task> get filteredTasks {
    return _tasks.where((t) {
      final matchesStatus = _filterStatus == 'all' || t.status.toLowerCase() == _filterStatus.toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          (t.siteName?.toLowerCase().contains(q) ?? false) ||
          (t.assignedToName?.toLowerCase().contains(q) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('tasks');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['tasks'] ?? res['data'] ?? res['items'] ?? [];
      }
      _tasks = rawList
          .whereType<Map>()
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تحميل خطط العمل';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<bool> saveTask(Map<String, dynamic> data) async {
    try {
      await api.post('work-plan-save', data);
      await fetchTasks();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل حفظ خطة العمل';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelTask(int taskId) async {
    try {
      await api.post('work-plan-cancel', {'task_id': taskId});
      await fetchTasks();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل إلغاء خطة العمل';
      notifyListeners();
      return false;
    }
  }
}
