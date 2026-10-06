import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/warehouse_move.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'sign_transaction_screen.dart';

class WarehouseMovesScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const WarehouseMovesScreen({super.key, required this.api, this.drawer});

  @override
  State<WarehouseMovesScreen> createState() => _WarehouseMovesScreenState();
}

class _WarehouseMovesScreenState extends State<WarehouseMovesScreen> {
  List<WarehouseMove> _moves = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ القاعدة الذهبية: جلب البيانات دائماً من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('warehouse-moves');
      if (!mounted) return;
      setState(() {
        _moves = (res as List).map((e) => WarehouseMove.fromJson(e)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ أثناء تحميل حركات المخزن';
        _loading = false;
      });
    }
  }

  Future<void> _signMove(WarehouseMove move) async {
    final signed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SignTransactionScreen(api: widget.api, move: move),
      ),
    );

    // ✅ إعادة الجلب بعد التوقيع
    if (signed == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل التوقيع وتحديث الحركة بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  List<WarehouseMove> get _filteredMoves {
    if (_filter == 'all') return _moves;
    if (_filter == 'unsigned') {
      return _moves.where((m) => m.signatureId == null || m.signedBy == null || m.signedBy!.isEmpty).toList();
    }
    if (_filter == 'signed') {
      return _moves.where((m) => m.signatureId != null || (m.signedBy != null && m.signedBy!.isNotEmpty)).toList();
    }
    return _moves;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('حركات الصرف والتوريد المخزني'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل حركات المخزن...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredMoves.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد حركات مخزنية',
                                message: 'لم يتم العثور على أي عمليات جرد أو صرف بالحالة المحددة',
                                icon: Icons.warehouse_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredMoves.length,
                                itemBuilder: (context, index) {
                                  final move = _filteredMoves[index];
                                  return _buildMoveCard(move);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFiltersHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'الكل (${_moves.length})'),
            _buildFilterChip('unsigned', 'بحاجة إلى توقيع'),
            _buildFilterChip('signed', 'موقّعة ومعتمدة'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String val, String label) {
    final isSelected = _filter == val;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
        selected: isSelected,
        selectedColor: AppTheme.primaryDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _filter = val),
      ),
    );
  }

  Widget _buildMoveCard(WarehouseMove move) {
    final isSigned = move.signatureId != null || (move.signedBy != null && move.signedBy!.isNotEmpty);

    Color typeColor = AppTheme.primaryTeal;
    String typeText = move.type;

    if (move.type == 'out') {
      typeColor = AppTheme.danger;
      typeText = 'صرف موقع';
    } else if (move.type == 'in') {
      typeColor = AppTheme.success;
      typeText = 'توريد';
    } else {
      typeColor = AppTheme.warning;
      typeText = 'تسوية';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    move.itemName ?? 'مادة #${move.itemId}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    typeText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'الكمية: ${move.quantity} ${move.unit ?? ""}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (move.unitPrice > 0) ...[
                  const SizedBox(width: 14),
                  Text(
                    'السعر: ${move.unitPrice} د.ع',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
            if (move.siteName != null && move.siteName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'الموقع: ${move.siteName}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.accentCyan),
                  ),
                ],
              ),
            ],
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isSigned)
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        'موقّع بواسطة: ${move.signedBy}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.warning),
                      SizedBox(width: 4),
                      Text(
                        'غير موقّع',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppTheme.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (!isSigned)
                  FilledButton.icon(
                    onPressed: () => _signMove(move),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.draw_rounded, size: 14),
                    label: const Text('توقيع الآن', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}