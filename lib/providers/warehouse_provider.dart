import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/warehouse_item.dart';
import '../models/warehouse_move.dart';
import '../services/admin_api.dart';

/// موفر حالة المخزن وحركات التوريد والصرف والتوقيع الرقمي
class WarehouseProvider extends ChangeNotifier {
  final AdminApi api;

  WarehouseProvider({AdminApi? api}) : api = api ?? AdminApi();

  List<WarehouseMove> _moves = [];
  List<WarehouseItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String _moveFilter = 'all';

  List<WarehouseMove> get moves => _moves;
  List<WarehouseItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get moveFilter => _moveFilter;

  int get unsignedMovesCount => _moves.where((m) => !m.isSigned).length;
  int get signedMovesCount => _moves.where((m) => m.isSigned).length;

  List<WarehouseMove> get filteredMoves {
    if (_moveFilter == 'unsigned') {
      return _moves.where((m) => !m.isSigned).toList();
    }
    if (_moveFilter == 'signed') {
      return _moves.where((m) => m.isSigned).toList();
    }
    return _moves;
  }

  void setFilter(String filter) {
    _moveFilter = filter;
    notifyListeners();
  }

  Future<void> fetchMoves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('warehouse-moves');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['moves'] ?? res['data'] ?? res['items'] ?? [];
      }
      _moves = rawList
          .whereType<Map>()
          .map((e) => WarehouseMove.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تحميل حركات المخزن';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<void> fetchItems() async {
    try {
      final res = await api.get('warehouse-items');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['items'] ?? res['data'] ?? [];
      }
      _items = rawList
          .whereType<Map>()
          .map((e) => WarehouseItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> signMove({
    required int moveId,
    required String signatureBase64,
  }) async {
    try {
      await api.post('transaction-sign', {
        'transaction_id': moveId,
        'signature_data': signatureBase64,
      });
      await fetchMoves();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل تسجيل التوقيع الرقمي';
      notifyListeners();
      return false;
    }
  }
}
