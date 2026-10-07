import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/user.dart';
import '../services/admin_api.dart';

/// موفر حالة إدارة المستخدمين والكوادر الميدانية
class UsersProvider extends ChangeNotifier {
  final AdminApi api;

  UsersProvider({AdminApi? api}) : api = api ?? AdminApi();

  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  String _filterRole = 'all';
  String _searchQuery = '';

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterRole => _filterRole;
  String get searchQuery => _searchQuery;

  List<User> get filteredUsers {
    return _users.where((u) {
      final matchesRole = _filterRole == 'all' || u.role.trim().toLowerCase() == _filterRole.trim().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      return matchesRole && matchesSearch;
    }).toList();
  }

  void setRoleFilter(String role) {
    _filterRole = role;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('users');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        if (res['users'] is List) {
          rawList = res['users'] as List;
        } else if (res['data'] is List) {
          rawList = res['data'] as List;
        } else if (res['items'] is List) {
          rawList = res['items'] as List;
        }
      }
      _users = rawList
          .whereType<Map>()
          .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تحميل المستخدمين';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<bool> saveUser(Map<String, dynamic> data) async {
    try {
      await api.post('user-save', data);
      await fetchUsers();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل حفظ بيانات المستخدم';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserStatus(User user) async {
    final nextStatus = user.isActive == 1 ? 0 : 1;
    try {
      await api.post('user-status', {
        'user_id': user.id,
        'is_active': nextStatus,
      });
      await fetchUsers();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل تعديل حالة المستخدم';
      notifyListeners();
      return false;
    }
  }
}
