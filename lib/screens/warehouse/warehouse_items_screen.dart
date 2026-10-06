import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/warehouse_item.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class WarehouseItemsScreen extends StatefulWidget {
  final AdminApi api;

  const WarehouseItemsScreen({super.key, required this.api});

  @override
  State<WarehouseItemsScreen> createState() => _WarehouseItemsScreenState();
}

class _WarehouseItemsScreenState extends State<WarehouseItemsScreen> {
  List<WarehouseItem> _items = [];
  List<WarehouseCategory> _categories = [];
  bool _loading = true;
  String? _error;
  bool _onlyLowStock = false;
  int? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ جلب البيانات من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final itemsRes = await widget.api.get('warehouse-items');
      final catsRes = await widget.api.get('warehouse-categories');

      if (!mounted) return;

      setState(() {
        _items = (itemsRes as List).map((e) => WarehouseItem.fromJson(e)).toList();
        _categories = (catsRes as List).map((e) => WarehouseCategory.fromJson(e)).toList();
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
        _error = 'حدث خطأ أثناء تحميل مواد المخزن';
        _loading = false;
      });
    }
  }

  List<WarehouseItem> get _filteredItems {
    return _items.where((it) {
      final matchesLow = !_onlyLowStock || it.isLowStock;
      final matchesCat = _selectedCategoryId == null || it.categoryId == _selectedCategoryId;
      final matchesSearch = _searchQuery.isEmpty ||
          it.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          it.code.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesLow && matchesCat && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزن والمستودع الرئيسي'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل المواد والكميات...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredItems.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد مواد مخزنية',
                                message: 'لم يتم العثور على أي مواد مطابقة للبحث أو معايير الفلترة',
                                icon: Icons.inventory_2_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return _buildItemCard(item);
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
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'بحث باسم المادة أو الكود...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('المواد دون الحد الأدنى فقط ⚠️',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  selected: _onlyLowStock,
                  selectedColor: AppTheme.dangerLight,
                  checkmarkColor: AppTheme.danger,
                  labelStyle: TextStyle(
                    fontFamily: 'Cairo',
                    color: _onlyLowStock ? AppTheme.danger : AppTheme.textSecondary,
                    fontWeight: _onlyLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) => setState(() => _onlyLowStock = val),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('جميع الفئات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  selected: _selectedCategoryId == null,
                  selectedColor: AppTheme.primaryDark,
                  labelStyle: TextStyle(
                    color: _selectedCategoryId == null ? Colors.white : AppTheme.textSecondary,
                  ),
                  onSelected: (_) => setState(() => _selectedCategoryId = null),
                ),
                ..._categories.map((cat) {
                  final isSel = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      selected: isSel,
                      selectedColor: AppTheme.primaryDark,
                      labelStyle: TextStyle(color: isSel ? Colors.white : AppTheme.textSecondary),
                      onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(WarehouseItem item) {
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
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (item.isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'نقص مخزني',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.categoryName != null && item.categoryName!.isNotEmpty)
                  Text(
                    'الفئة: ${item.categoryName}  ·  ',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
                if (item.code.isNotEmpty)
                  Text(
                    'الكود: ${item.code}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary, fontSize: 13),
                    children: [
                      const TextSpan(text: 'الرصيد الحالي: '),
                      TextSpan(
                        text: '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.isLowStock ? AppTheme.danger : AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'الحد الأدنى: ${item.minQuantity} ${item.unit}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}