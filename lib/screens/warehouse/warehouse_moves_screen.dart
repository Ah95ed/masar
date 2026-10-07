import '../../widgets/auto_refresh_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/warehouse_move.dart';
import '../../providers/warehouse_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().fetchMoves();
    });
  }

  Future<void> _signMove(WarehouseMove move) async {
    final signed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SignTransactionScreen(api: widget.api, move: move),
      ),
    );

    if (signed == true && mounted) {
      await context.read<WarehouseProvider>().fetchMoves();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم توقيع واعتماد الحركة بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final whProv = context.watch<WarehouseProvider>();
    final moves = whProv.filteredMoves;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 30),
      onRefresh: () => whProv.fetchMoves(),
      child: Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('توقيع حركات المخزن والمستودع'),
      ),
      body: whProv.isLoading && whProv.moves.isEmpty
          ? const LoadingState(message: 'جاري تحميل حركات المخزن...')
          : whProv.error != null && whProv.moves.isEmpty
              ? ErrorState(message: whProv.error!, onRetry: () => whProv.fetchMoves())
              : RefreshIndicator(
                  onRefresh: () => whProv.fetchMoves(),
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFilterBar(whProv),
                      Expanded(
                        child: moves.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد حركات مخزنية',
                                message: 'لم يتم العثور على أي حركات تطابق الفلتر المحدد',
                                icon: Icons.warehouse_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: moves.length,
                                itemBuilder: (context, index) {
                                  final move = moves[index];
                                  return _buildMoveTile(move);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildFilterBar(WarehouseProvider prov) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'كافة الحركات (${prov.moves.length})', prov),
            _buildFilterChip('unsigned', 'بحاجة إلى توقيع (${prov.unsignedMovesCount})', prov),
            _buildFilterChip('signed', 'موقّعة ومعتمدة (${prov.signedMovesCount})', prov),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, WarehouseProvider prov) {
    final isSelected = prov.moveFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => prov.setFilter(filter),
        selectedColor: AppTheme.primaryDark,
        backgroundColor: Colors.grey.shade100,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      ),
    );
  }

  Widget _buildMoveTile(WarehouseMove move, {bool isGrid = false}) {
    final isSigned = move.isSigned;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSigned ? AppTheme.border : AppTheme.warning.withOpacity(0.5),
          width: isSigned ? 1 : 1.5,
        ),
      ),
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isSigned ? AppTheme.success : AppTheme.warning).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSigned ? 'معتمدة وموقّعة' : 'بحاجة لتوقيع',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSigned ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(move.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    move.typeLabel,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(move.type),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'الكمية: ${move.quantity} ${move.unit ?? ""}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (move.totalPrice > 0)
                  Text(
                    '${move.totalPrice.toStringAsFixed(0)} \$',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
              ],
            ),
            if (move.siteName != null || move.supplier != null || move.reason != null) ...[
              const SizedBox(height: 6),
              Text(
                move.siteName != null
                    ? 'الموقع: ${move.siteName}'
                    : move.supplier != null
                        ? 'المورد: ${move.supplier}'
                        : 'السبب: ${move.reason}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const Divider(height: 18),
            Row(
              children: [
                if (isSigned) ...[
                  const Icon(Icons.verified_outlined, size: 16, color: AppTheme.success),
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
                ] else ...[
                  const Icon(Icons.pending_actions_outlined, size: 16, color: AppTheme.warning),
                  const SizedBox(width: 4),
                  const Text(
                    'بانتظار توقيع الإدارة أو المستلم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
                const Spacer(),
                if (!isSigned)
                  ElevatedButton.icon(
                    onPressed: () => _signMove(move),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.draw_rounded, size: 16),
                    label: const Text(
                      'توقيع الآن',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'in':
        return AppTheme.success;
      case 'out':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }
}
