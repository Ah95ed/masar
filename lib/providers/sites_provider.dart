import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/site.dart';
import '../services/admin_api.dart';

/// موفر حالة إدارة المواقع والمشاريع
class SitesProvider extends ChangeNotifier {
  final AdminApi api;

  SitesProvider({AdminApi? api}) : api = api ?? AdminApi();

  List<Site> _sites = [];
  bool _isLoading = false;
  String? _error;
  String _filterStatus = 'all';
  String _searchQuery = '';

  List<Site> get sites => _sites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  List<Site> get filteredSites {
    return _sites.where((s) {
      final matchesStatus = _filterStatus == 'all' || s.status.toLowerCase() == _filterStatus.toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.code.toLowerCase().contains(q) ||
          s.clientName.toLowerCase().contains(q);
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

  Future<void> fetchSites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('sites');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['sites'] ?? res['data'] ?? res['items'] ?? [];
      }
      _sites = rawList
          .whereType<Map>()
          .map((e) => Site.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تحميل المواقع';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<bool> saveSite(Map<String, dynamic> data) async {
    try {
      await api.post('site-save', data);
      await fetchSites();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل حفظ بيانات الموقع';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSite(int siteId) async {
    try {
      await api.post('site-cancel', {'site_id': siteId});
      await fetchSites();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل إلغاء الموقع';
      notifyListeners();
      return false;
    }
  }
}
