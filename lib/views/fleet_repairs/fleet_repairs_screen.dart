import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/machinery_model.dart';
import '../../models/repair_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

/// شاشة إدارة أسطول الآليات وعمليات الصيانة والإصلاح
class FleetRepairsScreen extends StatefulWidget {
  const FleetRepairsScreen({super.key});

  @override
  State<FleetRepairsScreen> createState() => _FleetRepairsScreenState();
}

class _FleetRepairsScreenState extends State<FleetRepairsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ManagementProvider>();
      p.fetchMachinery();
      p.fetchRepairs();
      p.fetchSites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== حوار إضافة آلية جديدة ====================
  void _showMachineryDialog([MachineryModel? machine]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: machine?.name);
    final codeCtrl = TextEditingController(text: machine?.code);
    final typeCtrl = TextEditingController(text: machine?.type);
    final plateCtrl = TextEditingController(text: machine?.plateNumber);
    final opCtrl = TextEditingController(text: machine?.operatorName);
    final prov = context.read<ManagementProvider>();
    int? selectedSiteId = machine?.siteId ?? (prov.sites.isNotEmpty ? prov.sites.first.id : null);
    String status = machine?.status ?? 'operational';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(machine == null ? 'إضافة آلية / معدة جديدة' : 'تعديل بيانات الآلية'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم الآلية أو المعدة *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: codeCtrl,
                            decoration: const InputDecoration(labelText: 'كود الآلية (Code)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: typeCtrl,
                            decoration: const InputDecoration(labelText: 'نوع الآلية (حفارة، رافعة...)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: plateCtrl,
                            decoration: const InputDecoration(labelText: 'رقم اللوحة / الشاسيه'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: opCtrl,
                            decoration: const InputDecoration(labelText: 'اسم السائق / المشغل'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedSiteId,
                      decoration: const InputDecoration(labelText: 'الموقع المتواجدة فيه'),
                      items: prov.sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setDialogState(() => selectedSiteId = val),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'الحالة التشغيلية'),
                      items: const [
                        DropdownMenuItem(value: 'operational', child: Text('تعمل بكفاءة (Operational)')),
                        DropdownMenuItem(value: 'under_maintenance', child: Text('تحت الصيانة (Maintenance)')),
                        DropdownMenuItem(value: 'idle', child: Text('جاهزة بدون عمل (Idle)')),
                        DropdownMenuItem(value: 'broken', child: Text('معطلة (Broken)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
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
                    if (machine != null) 'id': machine.id,
                    'name': nameCtrl.text.trim(),
                    if (codeCtrl.text.isNotEmpty) 'code': codeCtrl.text.trim(),
                    if (typeCtrl.text.isNotEmpty) 'type': typeCtrl.text.trim(),
                    if (plateCtrl.text.isNotEmpty) 'plate_number': plateCtrl.text.trim(),
                    if (opCtrl.text.isNotEmpty) 'operator_name': opCtrl.text.trim(),
                    'site_id': selectedSiteId,
                    'status': status,
                  };

                  final ok = await prov.saveMachinery(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ بيانات الآلية بنجاح.'), backgroundColor: AppTheme.successColor),
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

  // ==================== حوار إنشاء أمر صيانة ====================
  void _showRepairDialog([MachineryModel? defaultMachine]) {
    final formKey = GlobalKey<FormState>();
    final issueCtrl = TextEditingController();
    final actionCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: '0');
    final workshopCtrl = TextEditingController();
    final prov = context.read<ManagementProvider>();

    int? selectedMachineryId = defaultMachine?.id ?? (prov.machinery.isNotEmpty ? prov.machinery.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('فتح أمر صيانة وإصلاح آلية'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedMachineryId,
                      decoration: const InputDecoration(labelText: 'الآلية المعنية *'),
                      items: prov.machinery
                          .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.code ?? ""})')))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedMachineryId = val),
                      validator: (v) => v == null ? 'يرجى اختيار الآلية' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: issueCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'وصف العطل أو المشكلة الفنية *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: workshopCtrl,
                      decoration: const InputDecoration(labelText: 'اسم ورشة الصيانة أو الفني المسؤول'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'التكلفة التقديرية للصيانة'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: actionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'الإجراءات المتخذة أو قطع الغيار المطلوبة'),
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
                    'machinery_id': selectedMachineryId,
                    'issue_description': issueCtrl.text.trim(),
                    if (actionCtrl.text.isNotEmpty) 'action_taken': actionCtrl.text.trim(),
                    'cost': double.tryParse(costCtrl.text) ?? 0.0,
                    if (workshopCtrl.text.isNotEmpty) 'workshop_name': workshopCtrl.text.trim(),
                    'status': 'in_progress',
                  };

                  final ok = await prov.createRepair(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تسجيل أمر الصيانة بنجاح.'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: const Text('إصدار أمر الصيانة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateRepairStatusDialog(RepairModel repair) {
    String status = repair.status;
    final costCtrl = TextEditingController(text: repair.cost.toString());
    final actionCtrl = TextEditingController(text: repair.actionTaken);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تحديث أمر الصيانة #${repair.id}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'حالة الصيانة'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
                    DropdownMenuItem(value: 'in_progress', child: Text('جاري العمل والإصلاح')),
                    DropdownMenuItem(value: 'completed', child: Text('تم الإنجاز والإصلاح')),
                    DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'التكلفة الفعلية النهائية'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: actionCtrl,
                  decoration: const InputDecoration(labelText: 'تقرير ما تم تنفيذه'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await context.read<ManagementProvider>().updateRepair({
                    'repair_id': repair.id,
                    'status': status,
                    'cost': double.tryParse(costCtrl.text) ?? repair.cost,
                    'action_taken': actionCtrl.text.trim(),
                  });
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث سجل الصيانة بنجاح.'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: const Text('تحديث'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الآليات والأسطول والصيانة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.precision_manufacturing_rounded), text: 'أسطول الآليات والمعدات'),
            Tab(icon: Icon(Icons.build_circle_rounded), text: 'سجلات الصيانة والإصلاح'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMachineryTab(),
          _buildRepairsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_fleet_repairs_screen',
        onPressed: () {
          if (_tabController.index == 0) {
            _showMachineryDialog();
          } else {
            _showRepairDialog();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'إضافة آلية' : 'أمر صيانة'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMachineryTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.machineryState == LoadingState.loading && prov.machinery.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل أسطول الآليات...');
    }

    if (prov.machineryState == LoadingState.error && prov.machinery.isEmpty) {
      return ErrorView(
        message: prov.machineryError ?? 'تعذر تحميل الآليات',
        onRetry: () => prov.fetchMachinery(),
      );
    }

    if (prov.machinery.isEmpty) {
      return EmptyView(
        title: 'لا توجد آليات مسجلة',
        message: 'اضغط على زر الإضافة لتسجيل الحفارات والرافعات والشاحنات في المنظومة.',
        icon: Icons.precision_manufacturing_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchMachinery(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.machinery.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final m = prov.machinery[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            if (m.code != null || m.type != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${m.code ?? ""} • ${m.type ?? ""}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      StatusBadge(status: m.status),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m.siteName ?? 'المستودع الرئيسي',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      if (m.operatorName != null) ...[
                        const Icon(Icons.person_outline, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'المشغل: ${m.operatorName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('تعديل'),
                        onPressed: () => _showMachineryDialog(m),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
                        icon: const Icon(Icons.build_rounded, size: 16),
                        label: const Text('فتح أمر صيانة'),
                        onPressed: () => _showRepairDialog(m),
                      ),
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

  Widget _buildRepairsTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.repairsState == LoadingState.loading && prov.repairs.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل سجلات الصيانة...');
    }

    if (prov.repairsState == LoadingState.error && prov.repairs.isEmpty) {
      return ErrorView(
        message: prov.repairsError ?? 'تعذر تحميل الصيانة',
        onRetry: () => prov.fetchRepairs(),
      );
    }

    if (prov.repairs.isEmpty) {
      return EmptyView(
        title: 'لا توجد عمليات صيانة',
        message: 'جميع أوامر الإصلاح والصيانة الدورية للمعدات ستظهر هنا.',
        icon: Icons.build_circle_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchRepairs(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.repairs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = prov.repairs[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (r.isCompleted ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: r.isCompleted ? Colors.green.shade800 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.machineryName ?? 'آلية #${r.machineryId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Text(
                        ArabicHelpers.formatCurrency(r.cost),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'العطل: ${r.issueDescription}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  ),
                  if (r.actionTaken != null && r.actionTaken!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'الإجراء: ${r.actionTaken}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      if (r.workshopName != null) ...[
                        const Icon(Icons.home_repair_service_outlined, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(r.workshopName!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.update_rounded, size: 14),
                        label: const Text('تحديث الحالة والتكلفة', style: TextStyle(fontSize: 11)),
                        onPressed: () => _showUpdateRepairStatusDialog(r),
                      ),
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
}
