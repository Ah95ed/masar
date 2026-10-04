import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/work_plan_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

/// شاشة خطط العمل والمهام التنفيذية المستقلة (إضافة، تعديل، حذف، وإلغاء)
class WorkPlansScreen extends StatefulWidget {
  const WorkPlansScreen({super.key});

  @override
  State<WorkPlansScreen> createState() => _WorkPlansScreenState();
}

class _WorkPlansScreenState extends State<WorkPlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ManagementProvider>();
      p.fetchWorkPlans();
      p.fetchSites();
      p.fetchUsers();
    });
  }

  // ==================== حوار مرتب وأنيق لإنشاء/تعديل خطة العمل ====================
  void _showWorkPlanDialog([WorkPlanModel? plan]) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: plan?.title);
    final descCtrl = TextEditingController(text: plan?.description);
    final prov = context.read<ManagementProvider>();

    int? selectedSiteId = plan?.siteId ?? (prov.sites.isNotEmpty ? prov.sites.first.id : null);
    int? selectedEngineerId = plan?.assignedTo;
    bool isBroadcast = plan?.isBroadcast ?? false;
    String priority = plan?.priority ?? 'medium';
    final isEdit = plan != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_calendar_rounded : Icons.post_add_rounded,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'تعديل خطة العمل التنفيذية' : 'إصدار خطة عمل جديدة',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اختيار الموقع
                      DropdownButtonFormField<int>(
                        value: selectedSiteId,
                        decoration: InputDecoration(
                          hintText: 'اختر موقع العمل المستهدف *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: prov.sites
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedSiteId = val),
                        validator: (v) => v == null ? 'يرجى اختيار الموقع المستهدف' : null,
                      ),
                      const SizedBox(height: 12),

                      // عنوان خطة العمل
                      TextFormField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'عنوان الخطة أو المهمة التنفيذية *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'يرجى كتابة عنوان الخطة' : null,
                      ),
                      const SizedBox(height: 12),

                      // مستوى الأولوية
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: InputDecoration(
                          hintText: 'مستوى الأولوية والضرورة',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('منخفضة (Low)')),
                          DropdownMenuItem(value: 'medium', child: Text('متوسطة (Medium)')),
                          DropdownMenuItem(value: 'high', child: Text('عالية (High)')),
                          DropdownMenuItem(value: 'urgent', child: Text('عاجلة جداً (Urgent)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => priority = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // خيار التعميم أو التكليف الفردي
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isBroadcast ? Colors.purple.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isBroadcast ? Colors.purple.shade200 : Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('تعميم لكافة الفرق والمهندسين بالموقع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: const Text('لا يتم حصر المهمة بمهندس واحد عند تفعيل التعميم', style: TextStyle(fontSize: 11)),
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
                              const Divider(height: 12),
                              DropdownButtonFormField<int>(
                                value: selectedEngineerId,
                                decoration: InputDecoration(
                                  labelText: 'المهندس المكلف بالمتابعة',
                                  prefixIcon: const Icon(Icons.person_pin_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                                items: prov.users
                                    .where((u) => u.role == 'engineer')
                                    .map((u) => DropdownMenuItem(value: u.id, child: Text(u.displayName)))
                                    .toList(),
                                onChanged: (val) => setDialogState(() => selectedEngineerId = val),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // الوصف والتوجيهات
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'المواصفات الفنية والتوجيهات التنفيذية',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: Icon(isEdit ? Icons.save_rounded : Icons.check_circle_rounded),
                label: Text(isEdit ? 'حفظ التعديلات' : 'إصدار الخطة'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    if (plan != null) 'id': plan.id,
                    if (plan != null) 'task_id': plan.id,
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
                      SnackBar(
                        content: Text(isEdit ? 'تم تعديل خطة العمل بنجاح.' : 'تم إصدار خطة العمل بنجاح.'),
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

  // ==================== حوار حذف أو إلغاء الخطة ====================
  void _confirmDeleteOrCancelPlan(WorkPlanModel plan) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: AppTheme.dangerColor),
              SizedBox(width: 8),
              Text('خيارات حذف / إلغاء الخطة'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الخطة: "${plan.title}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              const Text(
                'يمكنك إلغاء الخطة مع بقائها في السجل كملغية أو حذفها نهائياً من قاعدة البيانات:',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('رجوع')),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warningColor),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('إلغاء الخطة'),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().cancelWorkPlan(plan.id);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إلغاء خطة العمل.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor, foregroundColor: Colors.white),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('حذف نهائي'),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().deleteWorkPlan(plan.id);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف خطة العمل نهائياً.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('خطط العمل والمهام التنفيذية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الخطط',
            onPressed: () => prov.fetchWorkPlans(siteId: prov.selectedPlanSiteId),
          ),
        ],
      ),
      body: Column(
        children: [
          // تصفية حسب الموقع
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: DropdownButtonFormField<int?>(
              value: prov.selectedPlanSiteId,
              decoration: InputDecoration(
                labelText: 'تصفية حسب موقع العمل',
                prefixIcon: const Icon(Icons.filter_alt_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('كافة مواقع العمل')),
                ...prov.sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (val) {
                prov.fetchWorkPlans(siteId: val);
              },
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (prov.workPlansState == LoadingState.loading && prov.workPlans.isEmpty) {
                  return const LoadingWidget(message: 'جاري تحميل خطط العمل...');
                }

                if (prov.workPlansState == LoadingState.error && prov.workPlans.isEmpty) {
                  return ErrorView(
                    message: prov.workPlansError ?? 'تعذر تحميل الخطط',
                    onRetry: () => prov.fetchWorkPlans(siteId: prov.selectedPlanSiteId),
                  );
                }

                if (prov.workPlans.isEmpty) {
                  return EmptyView(
                    title: 'لا توجد خطط عمل مسجلة',
                    message: 'اضغط على زر الإضافة لإصدار خطة عمل جديدة وتكليف المهندسين.',
                    icon: Icons.assignment_outlined,
                    action: ElevatedButton.icon(
                      onPressed: () => _showWorkPlanDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('إصدار خطة عمل جديدة'),
                    ),
                  );
                }

                return RefreshIndicator(
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
                              if (plan.siteName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'الموقع: ${plan.siteName}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                                ),
                              ],
                              if (plan.description != null && plan.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  plan.description!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  maxLines: 3,
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
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('تعديل'),
                                    onPressed: () => _showWorkPlanDialog(plan),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor),
                                    tooltip: 'حذف / إلغاء الخطة',
                                    onPressed: () => _confirmDeleteOrCancelPlan(plan),
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
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_work_plans_screen',
        onPressed: () => _showWorkPlanDialog(),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('إصدار خطة عمل'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }
}
