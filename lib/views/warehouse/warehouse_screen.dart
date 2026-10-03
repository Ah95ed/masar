import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/warehouse_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';

/// شاشة إدارة المستودع، الأصناف، الفئات، وحركات الصرف والتوريد
class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ManagementProvider>();
      p.fetchWarehouseData();
      p.fetchSites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== حوار إضافة صنف مخزني ====================
  void _showItemDialog([WarehouseItemModel? item]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item?.name);
    final codeCtrl = TextEditingController(text: item?.code);
    final unitCtrl = TextEditingController(text: item?.unit ?? 'وحدة');
    final stockCtrl = TextEditingController(text: item?.currentStock.toString() ?? '0');
    final minStockCtrl = TextEditingController(text: item?.minStock.toString() ?? '0');
    final priceCtrl = TextEditingController(text: item?.unitPrice.toString() ?? '0');
    final locationCtrl = TextEditingController(text: item?.location);
    final prov = context.read<ManagementProvider>();
    int? selectedCatId = item?.categoryId ?? (prov.warehouseCategories.isNotEmpty ? prov.warehouseCategories.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(item == null ? 'إضافة صنف مخزني جديد' : 'تعديل بيانات الصنف'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم الصنف أو المادة *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: codeCtrl,
                            decoration: const InputDecoration(labelText: 'كود المادة (SKU)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: unitCtrl,
                            decoration: const InputDecoration(labelText: 'الوحدة (طن، كيس...)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedCatId,
                      decoration: const InputDecoration(labelText: 'التصنيف / الفئة'),
                      items: prov.warehouseCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setDialogState(() => selectedCatId = val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: minStockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الحد الأدنى للطلب'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'سعر الوحدة التقديري'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: locationCtrl,
                            decoration: const InputDecoration(labelText: 'موقع التخزين / الرف'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    if (item != null) 'id': item.id,
                    'name': nameCtrl.text.trim(),
                    if (codeCtrl.text.isNotEmpty) 'code': codeCtrl.text.trim(),
                    'unit': unitCtrl.text.trim(),
                    'category_id': selectedCatId,
                    'current_stock': double.tryParse(stockCtrl.text) ?? 0.0,
                    'min_stock': double.tryParse(minStockCtrl.text) ?? 0.0,
                    'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
                    if (locationCtrl.text.isNotEmpty) 'location': locationCtrl.text.trim(),
                    'status': 'active',
                  };

                  final ok = await prov.saveWarehouseItem(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ الصنف بنجاح.'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== حوار تسجيل حركة مخزنية ====================
  void _showMoveDialog([WarehouseItemModel? defaultItem]) {
    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final prov = context.read<ManagementProvider>();

    int? selectedItemId = defaultItem?.id ?? (prov.warehouseItems.isNotEmpty ? prov.warehouseItems.first.id : null);
    String moveType = 'out'; // out = صرف لموقع, in = توريد للمخزن, return = إرجاع
    int? selectedSiteId = prov.sites.isNotEmpty ? prov.sites.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل حركة مواد مخزنية'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedItemId,
                      decoration: const InputDecoration(labelText: 'المادة / الصنف *'),
                      items: prov.warehouseItems.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (رصيد: ${i.currentStock})'))).toList(),
                      onChanged: (val) => setDialogState(() => selectedItemId = val),
                      validator: (v) => v == null ? 'يرجى اختيار المادة' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: moveType,
                      decoration: const InputDecoration(labelText: 'نوع الحركة المخزنية'),
                      items: const [
                        DropdownMenuItem(value: 'out', child: Text('صرف إلى مشروع / موقع (Out)')),
                        DropdownMenuItem(value: 'in', child: Text('توريد جديد إلى المستودع (In)')),
                        DropdownMenuItem(value: 'return', child: Text('إرجاع مواد فائضة للمستودع (Return)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => moveType = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (moveType == 'out' || moveType == 'return') ...[
                      DropdownButtonFormField<int>(
                        value: selectedSiteId,
                        decoration: const InputDecoration(labelText: 'الموقع المستهدف'),
                        items: prov.sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) => setDialogState(() => selectedSiteId = val),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الكمية *'),
                      validator: (v) {
                        final q = double.tryParse(v ?? '');
                        if (q == null || q <= 0) return 'أدخل كمية صحيحة أكبر من الصفر';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'رقم الفاتورة أو سبب الصرف والملاحظات'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    'item_id': selectedItemId,
                    'move_type': moveType,
                    'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                    if (moveType != 'in') 'site_id': selectedSiteId,
                    if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                  };

                  final ok = await prov.createWarehouseMove(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تسجيل الحركة المخزنية بنجاح.'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: const Text('تسجيل الحركة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== حوار إضافة فئة مخزنية ====================
  void _showCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة فئة تصنيف جديدة للمستودع'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الفئة (مثل: مواد عزل، كهربائيات) *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'وصف الفئة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await context.read<ManagementProvider>().saveWarehouseCategory({
                  'name': nameCtrl.text.trim(),
                  if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ الفئة بنجاح.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
              child: const Text('حفظ الفئة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('المستودع والمخزون والمواد'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_rounded), text: 'أصناف المواد'),
            Tab(icon: Icon(Icons.swap_horiz_rounded), text: 'حركات الصرف والتوريد'),
            Tab(icon: Icon(Icons.category_rounded), text: 'فئات التصنيف'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsTab(),
          _buildMovesTab(),
          _buildCategoriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_warehouse_screen',
        onPressed: () {
          if (_tabController.index == 0) {
            _showItemDialog();
          } else if (_tabController.index == 1) {
            _showMoveDialog();
          } else {
            _showCategoryDialog();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0
            ? 'إضافة صنف'
            : _tabController.index == 1
                ? 'حركة مواد'
                : 'فئة جديدة'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildItemsTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.warehouseState == LoadingState.loading && prov.warehouseItems.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل أصناف المخزن...');
    }

    if (prov.warehouseState == LoadingState.error && prov.warehouseItems.isEmpty) {
      return ErrorView(message: prov.warehouseError ?? 'تعذر تحميل المخزن', onRetry: () => prov.fetchWarehouseData());
    }

    if (prov.warehouseItems.isEmpty) {
      return EmptyView(
        title: 'المستودع فارغ',
        message: 'أضف المواد الإنشائية والأصناف لمتابعة الأرصدة وحركات الصرف للمشاريع.',
        icon: Icons.inventory_2_outlined,
      );
    }

    final lowStockItems = prov.warehouseItems.where((i) => i.isLowStock).toList();

    return RefreshIndicator(
      onRefresh: () => prov.fetchWarehouseData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // تنبيه نقص المخزون إن وجد
          if (lowStockItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يوجد ${lowStockItems.length} صنف وصل إلى أو تجاوز حد الطلب الأدنى! يرجى التوريد فوراً.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...prov.warehouseItems.map((item) {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: item.isLowStock ? Colors.orange.shade200 : Colors.grey.shade200),
              ),
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                              if (item.code != null || item.categoryName != null) ...[
                                const SizedBox(height: 2),
                                Text('${item.code ?? ""} • ${item.categoryName ?? ""}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ],
                          ),
                        ),
                        if (item.isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                            child: const Text('مخزون منخفض', style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الرصيد المتوفر', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text('${item.currentStock} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('سعر الوحدة', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(ArabicHelpers.formatCurrency(item.unitPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('القيمة الإجمالية', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(ArabicHelpers.formatCurrency(item.totalValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0284C7))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('تعديل'),
                          onPressed: () => _showItemDialog(item),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0284C7)),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text('تسجيل صرف/توريد'),
                          onPressed: () => _showMoveDialog(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMovesTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.warehouseMoves.isEmpty) {
      return EmptyView(
        title: 'لا توجد حركات مخزنية',
        message: 'سجلات الصرف والتوريد والإرجاع ستظهر هنا بالتفصيل.',
        icon: Icons.history_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchWarehouseData(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.warehouseMoves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final m = prov.warehouseMoves[index];
          final isOut = m.moveType.toLowerCase() == 'out';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isOut ? Colors.orange : Colors.green).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOut ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
                      color: isOut ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.itemName ?? 'صنف مخزني', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${m.moveTypeLabel} • ${m.siteName ?? "المستودع"}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        if (m.notes != null) ...[
                          const SizedBox(height: 2),
                          Text(m.notes!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isOut ? "-" : "+"}${m.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isOut ? Colors.orange.shade800 : Colors.green.shade800,
                        ),
                      ),
                      if (m.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(m.createdAt!, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.warehouseCategories.isEmpty) {
      return EmptyView(
        title: 'لا توجد فئات تصنيف',
        message: 'أضف فئات مثل "مواد بناء"، "كهربائيات" لتنظيم المستودع.',
        icon: Icons.category_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: prov.warehouseCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cat = prov.warehouseCategories[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.folder_outlined, color: Color(0xFF0F172A))),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: cat.description != null ? Text(cat.description!, style: const TextStyle(fontSize: 12)) : null,
          ),
        );
      },
    );
  }
}
