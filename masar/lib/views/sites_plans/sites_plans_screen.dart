import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/site_model.dart';
import '../../models/work_plan_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

/// شاشة إدارة المواقع وخطط العمل التنفيذية للمدير العام
class SitesPlansScreen extends StatefulWidget {
  const SitesPlansScreen({super.key});

  @override
  State<SitesPlansScreen> createState() => _SitesPlansScreenState();
}

class _SitesPlansScreenState extends State<SitesPlansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ManagementProvider>();
      p.fetchSites();
      p.fetchWorkPlans();
      p.fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== حوار إنشاء/تعديل موقع ====================
  void _showSiteDialog([SiteModel? site]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: site?.name);
    final clientCtrl = TextEditingController(text: site?.clientName);
    final workDateCtrl = TextEditingController(text: site?.workDate ?? DateTime.now().toIso8601String().substring(0, 10));
    final startTimeCtrl = TextEditingController(text: site?.startTime ?? '08:00');
    final endTimeCtrl = TextEditingController(text: site?.endTime ?? '16:00');
    final locationCtrl = TextEditingController(text: site?.location);
    final budgetCtrl = TextEditingController(text: site?.budget?.toString() ?? '');
    final descCtrl = TextEditingController(text: site?.description);
    String status = site?.status ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(site == null ? 'إضافة موقع عمل جديد' : 'تعديل بيانات الموقع'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم الموقع / المشروع *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: clientCtrl,
                      decoration: const InputDecoration(labelText: 'اسم العميل / الجهة المالكة'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: workDateCtrl,
                            decoration: const InputDecoration(labelText: 'تاريخ العمل (YYYY-MM-DD)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: budgetCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الميزانية التقديرية'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: startTimeCtrl,
                            decoration: const InputDecoration(labelText: 'وقت البدء (08:00)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: endTimeCtrl,
                            decoration: const InputDecoration(labelText: 'وقت الانتهاء (16:00)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'الموقع الجغرافي / العنوان'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'حالة المشروع'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('نشط (Active)')),
                        DropdownMenuItem(value: 'completed', child: Text('مكتمل (Completed)')),
                        DropdownMenuItem(value: 'halted', child: Text('متوقف مؤقتاً (Halted)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'وصف المشروع والملاحظات'),
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
                    if (site != null) 'id': site.id,
                    'name': nameCtrl.text.trim(),
                    if (clientCtrl.text.isNotEmpty) 'client_name': clientCtrl.text.trim(),
                    if (workDateCtrl.text.isNotEmpty) 'work_date': workDateCtrl.text.trim(),
                    if (startTimeCtrl.text.isNotEmpty) 'start_time': startTimeCtrl.text.trim(),
                    if (endTimeCtrl.text.isNotEmpty) 'end_time': endTimeCtrl.text.trim(),
                    if (locationCtrl.text.isNotEmpty) 'location': locationCtrl.text.trim(),
                    if (budgetCtrl.text.isNotEmpty) 'budget': double.tryParse(budgetCtrl.text),
                    'status': status,
                    if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                  };

                  final ok = await context.read<ManagementProvider>().saveSite(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ بيانات الموقع بنجاح.'), backgroundColor: AppTheme.successColor),
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

  // ==================== حوار أرشفة/إلغاء الموقع ====================
  void _confirmCancelSite(SiteModel site) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.archive_outlined, color: AppTheme.warningColor),
              SizedBox(width: 8),
              Text('أرشفة وإلغاء الموقع'),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في أرشفة الموقع "${site.name}"؟\nسيتم تحويل الحالة إلى "ملغي" (cancelled) لحفظ التاريخ الإنشائي بدلاً من الحذف النهائي.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().cancelSite(site.id);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت أرشفة الموقع بنجاح.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
              child: const Text('تأكيد الأرشفة'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== حوار إنشاء خطة عمل ====================
  void _showWorkPlanDialog() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prov = context.read<ManagementProvider>();

    int? selectedSiteId = prov.sites.isNotEmpty ? prov.sites.first.id : null;
    int? selectedEngineerId;
    bool isBroadcast = false;
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إصدار خطة عمل / مهمة جديدة'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedSiteId,
                      decoration: const InputDecoration(labelText: 'الموقع المستهدف *'),
                      items: prov.sites
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedSiteId = val),
                      validator: (v) => v == null ? 'يرجى اختيار الموقع' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'عنوان خطة العمل *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'تفاصيل التوجيهات والتعليمات الفنية'),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('تعميم عام لجميع الفرق (Broadcast)', style: TextStyle(fontSize: 13)),
                      value: isBroadcast,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          isBroadcast = val;
                          if (val) selectedEngineerId = null;
                        });
                      },
                    ),
                    if (!isBroadcast) ...[
                      DropdownButtonFormField<int>(
                        value: selectedEngineerId,
                        decoration: const InputDecoration(labelText: 'تكليف مهندس مخصص'),
                        items: prov.users
                            .where((u) => u.role == 'engineer')
                            .map((u) => DropdownMenuItem(value: u.id, child: Text(u.displayName)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedEngineerId = val),
                      ),
                    ],
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'مستوى الأولوية'),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                        DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
                        DropdownMenuItem(value: 'high', child: Text('عالية')),
                        DropdownMenuItem(value: 'urgent', child: Text('عاجلة جداً')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => priority = val);
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
                    'site_id': selectedSiteId,
                    'title': titleCtrl.text.trim(),
                    if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                    'is_broadcast': isBroadcast ? 1 : 0,
                    if (!isBroadcast && selectedEngineerId != null) 'assigned_to': selectedEngineerId,
                    'priority': priority,
                  };

                  final ok = await prov.saveWorkPlan(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إصدار خطة العمل بنجاح.'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: const Text('إصدار الخطة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== حوار إلغاء خطة عمل ====================
  void _confirmCancelPlan(WorkPlanModel plan) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء خطة العمل'),
          content: Text('هل أنت متأكد من إلغاء الخطة "${plan.title}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().cancelWorkPlan(plan.id);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إلغاء خطة العمل بنجاح.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
              child: const Text('تأكيد الإلغاء'),
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
        title: const Text('إدارة المواقع وخطط العمل'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.location_city_rounded), text: 'مواقع المشاريع'),
            Tab(icon: Icon(Icons.assignment_turned_in_rounded), text: 'خطط العمل التنفيذية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSitesTab(),
          _buildPlansTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_sites_plans_screen',
        onPressed: () {
          if (_tabController.index == 0) {
            _showSiteDialog();
          } else {
            _showWorkPlanDialog();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'إضافة موقع' : 'خطة عمل جديدة'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSitesTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.sitesState == LoadingState.loading && prov.sites.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل مواقع العمل...');
    }

    if (prov.sitesState == LoadingState.error && prov.sites.isEmpty) {
      return ErrorView(
        message: prov.sitesError ?? 'تعذر تحميل المواقع',
        onRetry: () => prov.fetchSites(),
      );
    }

    if (prov.sites.isEmpty) {
      return EmptyView(
        title: 'لا توجد مواقع مسجلة',
        message: 'اضغط على زر الإضافة لإنشاء أول موقع عمل للمنظومة.',
        icon: Icons.domain_disabled_rounded,
        action: ElevatedButton.icon(
          onPressed: () => _showSiteDialog(),
          icon: const Icon(Icons.add),
          label: const Text('إضافة موقع جديد'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchSites(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.sites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final site = prov.sites[index];
          final isCancelled = site.isCancelled;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isCancelled ? Colors.red.shade100 : Colors.grey.shade200),
            ),
            color: isCancelled ? Colors.grey.shade50 : Colors.white,
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
                          color: (isCancelled ? Colors.grey : const Color(0xFF0284C7)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.apartment_rounded,
                          color: isCancelled ? Colors.grey : const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              site.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                color: isCancelled ? Colors.grey.shade600 : const Color(0xFF0F172A),
                              ),
                            ),
                            if (site.clientName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'العميل: ${site.clientName}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      StatusBadge(status: site.status),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      if (site.location != null) ...[
                        const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            site.location!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (site.budget != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          ArabicHelpers.formatCurrency(site.budget),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ],
                  ),
                  if (site.workDate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'التاريخ: ${site.workDate}  •  ساعات العمل: ${site.startTime ?? "--"} إلى ${site.endTime ?? "--"}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('تعديل'),
                        onPressed: () => _showSiteDialog(site),
                      ),
                      if (!isCancelled) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warningColor),
                          icon: const Icon(Icons.archive_outlined, size: 16),
                          label: const Text('أرشفة وإلغاء'),
                          onPressed: () => _confirmCancelSite(site),
                        ),
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

  Widget _buildPlansTab() {
    final prov = context.watch<ManagementProvider>();

    if (prov.workPlansState == LoadingState.loading && prov.workPlans.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل خطط العمل...');
    }

    if (prov.workPlansState == LoadingState.error && prov.workPlans.isEmpty) {
      return ErrorView(
        message: prov.workPlansError ?? 'تعذر تحميل الخطط',
        onRetry: () => prov.fetchWorkPlans(),
      );
    }

    return Column(
      children: [
        // تصفية حسب الموقع
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<int?>(
            value: prov.selectedPlanSiteId,
            decoration: InputDecoration(
              labelText: 'تصفية حسب الموقع',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('جميع المواقع')),
              ...prov.sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
            ],
            onChanged: (val) {
              prov.fetchWorkPlans(siteId: val);
            },
          ),
        ),
        Expanded(
          child: prov.workPlans.isEmpty
              ? EmptyView(
                  title: 'لا توجد خطط عمل',
                  message: 'قم بإصدار خطة عمل وتكليف المهندسين لمتابعة الإنجاز.',
                  icon: Icons.checklist_rtl_rounded,
                )
              : RefreshIndicator(
                  onRefresh: () => prov.fetchWorkPlans(siteId: prov.selectedPlanSiteId),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.workPlans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = prov.workPlans[index];
                      final isCancelled = plan.isCancelled;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: isCancelled ? Colors.grey.shade100 : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ArabicHelpers.getPriorityColor(plan.priority).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ArabicHelpers.translatePriority(plan.priority),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: ArabicHelpers.getPriorityColor(plan.priority),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (plan.isBroadcast)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('تعميم عام', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                    ),
                                  const Spacer(),
                                  StatusBadge(status: plan.status),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                plan.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if (plan.description != null && plan.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  plan.description!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_circle_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    plan.isBroadcast ? 'موجهة للجميع' : 'المكلف: ${plan.assignedToName ?? "مهندس موقع"}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const Spacer(),
                                  if (!isCancelled && !plan.isCompleted)
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.dangerColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                      icon: const Icon(Icons.cancel_outlined, size: 14),
                                      label: const Text('إلغاء الخطة', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _confirmCancelPlan(plan),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
