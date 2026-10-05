import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/warehouse_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';

import '../widgets/loading_widget.dart';

/// شاشة المخزن المستنسخة بدقة وعمق من Just_admin (warehouse.php, warehouse_items.php, warehouse_moves.php)
class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _filterOnlyLowStock = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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

  void _showItemDialog([WarehouseItemModel? item]) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: item?.code);
    final nameCtrl = TextEditingController(text: item?.name);
    final unitCtrl = TextEditingController(text: item?.unit ?? 'قطعة');
    final stockCtrl = TextEditingController(text: item?.currentStock.toString() ?? '0');
    final minStockCtrl = TextEditingController(text: item?.minStock.toString() ?? '0');
    final priceCtrl = TextEditingController(text: item?.unitPrice.toString() ?? '0');
    final locationCtrl = TextEditingController(text: item?.location);
    final notesCtrl = TextEditingController(text: item?.notes);
    final prov = context.read<ManagementProvider>();
    int? selectedCatId = item?.categoryId ?? (prov.warehouseCategories.isNotEmpty ? prov.warehouseCategories.first.id : null);
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.cyanPale, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory_2_rounded, color: AppTheme.cyan, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'تعديل بيانات المادة' : 'إضافة مادة جديدة',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx).size.height * 0.72,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: codeCtrl,
                              decoration: const InputDecoration(hintText: 'كود المادة (Code) *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(hintText: 'اسم المادة المخزنية *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: selectedCatId,
                        decoration: const InputDecoration(hintText: 'الفئة / التصنيف'),
                        items: prov.warehouseCategories
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedCatId = val),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: unitCtrl,
                              decoration: const InputDecoration(hintText: 'وحدة القياس (مثال: طن، متر، كيس)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: stockCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'الكمية الأولية / المتاحة'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: minStockCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'حد إعادة الطلب (تنبيه النقص)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'سعر الوحدة التقديري'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationCtrl,
                        decoration: const InputDecoration(labelText: 'مكان التخزين (الموقع/الرف)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'الملاحظات'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ink),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(isEdit ? 'حفظ التعديل' : 'حفظ المادة'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    if (isEdit) 'id': item.id,
                    'code': codeCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'category_id': selectedCatId,
                    'unit': unitCtrl.text.trim(),
                    'quantity': double.tryParse(stockCtrl.text) ?? 0.0,
                    'min_quantity': double.tryParse(minStockCtrl.text) ?? 0.0,
                    'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
                    if (locationCtrl.text.isNotEmpty) 'location': locationCtrl.text.trim(),
                    if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                  };
                  final ok = await prov.saveWarehouseItem(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'تم تحديث بيانات المادة بنجاح.' : 'تم إضافة المادة إلى المخزن.'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveDialog() {
    final formKey = GlobalKey<FormState>();
    final prov = context.read<ManagementProvider>();
    if (prov.warehouseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة مواد إلى المخزن أولاً قبل تسجيل حركة.'), backgroundColor: AppTheme.dangerColor),
      );
      return;
    }

    int selectedItemId = prov.warehouseItems.first.id;
    String moveType = 'in'; // in: وارد, out: صادر, adjust: تعديل رصيد
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: prov.warehouseItems.first.unitPrice.toString());
    final supplierCtrl = TextEditingController();
    final invoiceCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    int? selectedSiteId = prov.sites.isNotEmpty ? prov.sites.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.green, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'تسجيل حركة مخزنية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx).size.height * 0.72,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedItemId,
                        decoration: const InputDecoration(labelText: 'المادة *'),
                        items: prov.warehouseItems
                            .map((i) => DropdownMenuItem(
                                  value: i.id,
                                  child: Text(
                                    '${i.code ?? ""} - ${i.name} (المتاح: ${i.currentStock} ${i.unit})',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedItemId = val;
                              final itm = prov.warehouseItems.firstWhere((x) => x.id == val);
                              priceCtrl.text = itm.unitPrice.toString();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: moveType,
                        decoration: const InputDecoration(labelText: 'نوع الحركة *'),
                        items: const [
                          DropdownMenuItem(value: 'in', child: Text('وارد (شراء / توريد)')),
                          DropdownMenuItem(value: 'out', child: Text('صادر (صرف لموقع عمل)')),
                          DropdownMenuItem(value: 'adjust', child: Text('تعديل رصيد (تسوية جردية)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => moveType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'الكمية العددية *'),
                              validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0 ? 'كمية غير صالحة' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'سعر الوحدة التقديري'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (moveType == 'out') ...[
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: selectedSiteId,
                          decoration: const InputDecoration(labelText: 'موقع العمل المستهدف'),
                          items: prov.sites
                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => selectedSiteId = val),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (moveType == 'in') ...[
                        TextFormField(
                          controller: supplierCtrl,
                          decoration: const InputDecoration(labelText: 'المورد (Supplier)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: invoiceCtrl,
                          decoration: const InputDecoration(labelText: 'رقم الفاتورة (Invoice Number)'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: reasonCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'السبب / الملاحظات'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ink),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('تسجيل الحركة'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    'item_id': selectedItemId,
                    'type': moveType,
                    'move_type': moveType,
                    'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                    'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
                    if (moveType == 'out' && selectedSiteId != null) 'site_id': selectedSiteId,
                    if (supplierCtrl.text.isNotEmpty) 'supplier': supplierCtrl.text.trim(),
                    if (invoiceCtrl.text.isNotEmpty) 'invoice_number': invoiceCtrl.text.trim(),
                    if (reasonCtrl.text.isNotEmpty) 'reason': reasonCtrl.text.trim(),
                  };
                  final ok = await prov.createWarehouseMove(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تسجيل الحركة المخزنية بنجاح.'), backgroundColor: AppTheme.successColor),
                      );
                    } else if (prov.warehouseError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(prov.warehouseError!), backgroundColor: AppTheme.dangerColor),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryDialog([WarehouseCategoryModel? category]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: category?.name);
    final descCtrl = TextEditingController(text: category?.description);
    final isEdit = category != null;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(isEdit ? 'تعديل فئة' : 'إضافة فئة مواد جديدة'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الفئة *'),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ink),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await context.read<ManagementProvider>().saveWarehouseCategory({
                  if (isEdit) 'id': category.id,
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
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: const Text('المخزن'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cyan,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFCBD5E1),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'لوحة المخزن'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 20), text: 'إدارة المواد'),
            Tab(icon: Icon(Icons.swap_horiz_rounded, size: 20), text: 'حركات المخزن'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildItemsTab(),
          _buildMovesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_warehouse_screen',
        onPressed: () {
          if (_tabController.index == 1) {
            _showItemDialog();
          } else {
            _showMoveDialog();
          }
        },
        icon: Icon(
          _tabController.index == 1
              ? Icons.add_box_rounded
              : (_tabController.index == 0 ? Icons.swap_horiz_rounded : Icons.post_add_rounded),
        ),
        label: Text(
          _tabController.index == 1
              ? 'إضافة مادة جديدة'
              : (_tabController.index == 0 ? 'حركة جديدة' : 'تسجيل حركة مخزنية'),
        ),
        backgroundColor: AppTheme.ink,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildOverviewTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.warehouseState == LoadingState.loading && prov.warehouseItems.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل بيانات المخزن...');
    }

    final items = prov.warehouseItems;
    final lowItems = items.where((i) => i.isLowStock).toList();
    final totalValue = items.fold<double>(0.0, (acc, item) => acc + item.totalValue);
    final categoriesCount = prov.warehouseCategories.length;
    final moves = prov.warehouseMoves.take(8).toList();

    return RefreshIndicator(
      onRefresh: () => prov.fetchWarehouseData(),
      color: AppTheme.ink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    label: 'مواد نشطة',
                    value: '${items.length}',
                    icon: Icons.inventory_2_rounded,
                    accent: AppTheme.cyan,
                    tint: AppTheme.cyanPale,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    label: 'مواد منخفضة',
                    value: '${lowItems.length}',
                    icon: Icons.warning_amber_rounded,
                    accent: AppTheme.amber,
                    tint: AppTheme.amberPale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    label: 'قيمة المخزون',
                    value: ArabicHelpers.formatCurrency(totalValue),
                    icon: Icons.account_balance_wallet_rounded,
                    accent: AppTheme.green,
                    tint: AppTheme.greenPale,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    label: 'الفئات',
                    value: '$categoriesCount',
                    icon: Icons.grid_view_rounded,
                    accent: AppTheme.ink,
                    tint: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_rounded, color: AppTheme.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'مواد عند حد إعادة الطلب',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: const Text('إدارة المواد', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (lowItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text('جميع المواد فوق الحد الأدنى المطلوب', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lowItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (ctx, i) {
                        final item = lowItems[i];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.paper, borderRadius: BorderRadius.circular(4)),
                              child: Text(item.code ?? '#', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.redPale, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '${item.currentStock} ${item.unit}',
                                style: const TextStyle(color: AppTheme.red, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('الحد: ${item.minStock}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_rounded, color: AppTheme.cyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'آخر الحركات المسجلة',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _tabController.animateTo(2),
                        child: const Text('سجل الحركات', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (moves.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text('لا توجد حركات مسجلة حتى الآن', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: moves.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (ctx, i) {
                        final m = moves[i];
                        final isIn = m.moveType.toLowerCase() == 'in';
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isIn ? AppTheme.greenPale : AppTheme.amberPale,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isIn ? AppTheme.green : AppTheme.amber,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.itemName ?? 'مادة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(m.moveTypeLabel, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                                ],
                              ),
                            ),
                            Text('${m.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTab() {
    final prov = context.watch<ManagementProvider>();
    final allItems = prov.warehouseItems;
    final items = _filterOnlyLowStock ? allItems.where((i) => i.isLowStock).toList() : allItems;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي المواد: ${allItems.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.ink),
              ),
              Row(
                children: [
                  FilterChip(
                    label: const Text('نواقص فقط', style: TextStyle(fontSize: 11)),
                    selected: _filterOnlyLowStock,
                    selectedColor: AppTheme.amberPale,
                    onSelected: (val) => setState(() => _filterOnlyLowStock = val),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    icon: const Icon(Icons.category_outlined, size: 14),
                    label: const Text('الفئات', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showCategoriesBottomSheet(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? EmptyView(
                  title: 'لا توجد مواد مطابقة',
                  message: _filterOnlyLowStock ? 'لا توجد مواد تحت حد الطلب حالياً' : 'أضف مواد وأصناف جديدة للمخزن',
                  action: ElevatedButton(onPressed: () => _showItemDialog(), child: const Text('إضافة مادة')),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: item.isLowStock ? AppTheme.amber.withOpacity(0.5) : AppTheme.line),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.paper, borderRadius: BorderRadius.circular(4)),
                                child: Text(item.code ?? '#', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: item.isLowStock ? AppTheme.amberPale : AppTheme.greenPale,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.currentStock} ${item.unit}',
                                  style: TextStyle(
                                    color: item.isLowStock ? AppTheme.amber : AppTheme.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الفئة: ${item.categoryName ?? "عام"}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                              Text('سعر الوحدة: ${ArabicHelpers.formatCurrency(item.unitPrice)}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                              Text('الإجمالي: ${ArabicHelpers.formatCurrency(item.totalValue)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: AppTheme.cyan),
                                icon: const Icon(Icons.edit_outlined, size: 14),
                                label: const Text('تعديل', style: TextStyle(fontSize: 11)),
                                onPressed: () => _showItemDialog(item),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
                                icon: const Icon(Icons.delete_outline, size: 14),
                                label: const Text('تعطيل/حذف', style: TextStyle(fontSize: 11)),
                                onPressed: () => _confirmDisableItem(item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDisableItem(WarehouseItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعطيل المادة المخزنية'),
          content: Text('هل تريد تعطيل مادة "${item.name}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().setWarehouseItemStatus(item.id, 'inactive');
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعطيل المادة بنجاح.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
              child: const Text('تأكيد التعطيل'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Consumer<ManagementProvider>(
        builder: (ctx, prov, _) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('فئات المواد المسجلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ink, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('فئة جديدة', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCategoryDialog();
                      },
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (prov.warehouseCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('لا توجد فئات مسجلة', style: TextStyle(color: AppTheme.muted))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: prov.warehouseCategories.length,
                    separatorBuilder: (_, __) => const Divider(height: 10),
                    itemBuilder: (ctx, i) {
                      final cat = prov.warehouseCategories[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: cat.description != null ? Text(cat.description!, style: const TextStyle(fontSize: 11)) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCategoryDialog(cat);
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovesTab() {
    final prov = context.watch<ManagementProvider>();
    final moves = prov.warehouseMoves;

    if (moves.isEmpty) {
      return EmptyView(
        title: 'لا توجد حركات مخزنية',
        message: 'سجل حركات التوريد والصرف والتسوية الجردية',
        action: ElevatedButton(onPressed: () => _showMoveDialog(), child: const Text('تسجيل حركة')),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: moves.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final m = moves[i];
        final isIn = m.moveType.toLowerCase() == 'in';
        final isAdjust = m.moveType.toLowerCase() == 'adjust';

        Color badgeColor = isIn ? AppTheme.green : (isAdjust ? AppTheme.cyan : AppTheme.amber);
        Color badgeBg = isIn ? AppTheme.greenPale : (isAdjust ? AppTheme.cyanPale : AppTheme.amberPale);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.line),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(m.moveTypeLabel, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m.itemName ?? 'مادة مخزنية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Text(
                    '${m.quantity}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: badgeColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (m.siteName != null)
                    Text('الموقع: ${m.siteName}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                  if (m.supplier != null)
                    Text('المورد: ${m.supplier}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                  if (m.invoiceNumber != null)
                    Text('فاتورة: ${m.invoiceNumber}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                  if (m.totalPrice > 0)
                    Text('القيمة: ${ArabicHelpers.formatCurrency(m.totalPrice)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                ],
              ),
              if (m.notes != null && m.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('السبب: ${m.notes}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
              ],
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.createdAt ?? '', style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                  Text('المسؤول: ${m.createdBy ?? "الإدارة"}', style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: accent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent),
          ),
        ],
      ),
    );
  }
}



