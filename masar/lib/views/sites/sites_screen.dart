import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/site_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

/// شاشة مواقع العمل والمشاريع الإنشائية المستقلة (إضافة، تعديل، حذف، وأرشفة)
class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().fetchSites();
    });
  }

  // ==================== حوار مرتب وأنيق لإنشاء/تعديل الموقع (بدون حقل الميزانية) ====================
  void _showSiteDialog([SiteModel? site]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: site?.name);
    final clientCtrl = TextEditingController(text: site?.clientName);
    final workDateCtrl = TextEditingController(
      text: site?.workDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    final startTimeCtrl = TextEditingController(text: site?.startTime ?? '08:00');
    final endTimeCtrl = TextEditingController(text: site?.endTime ?? '16:00');
    final locationCtrl = TextEditingController(text: site?.location);
    final descCtrl = TextEditingController(text: site?.description);
    String status = site?.status ?? 'active';

    final isEdit = site != null;

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
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.add_business_rounded,
                    color: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'تعديل بيانات الموقع الإنشائي' : 'إضافة موقع عمل جديد',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم الموقع
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم موقع العمل / المشروع *',
                          prefixIcon: const Icon(Icons.apartment_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'يرجى كتابة اسم الموقع' : null,
                      ),
                      const SizedBox(height: 12),

                      // اسم العميل أو المالك
                      TextFormField(
                        controller: clientCtrl,
                        decoration: InputDecoration(
                          labelText: 'العميل أو الجهة المستفيدة',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // الموقع الجغرافي / العنوان
                      TextFormField(
                        controller: locationCtrl,
                        decoration: InputDecoration(
                          labelText: 'الموقع الجغرافي / العنوان والمدينة',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // تاريخ العمل
                      TextFormField(
                        controller: workDateCtrl,
                        decoration: InputDecoration(
                          labelText: 'تاريخ بدء العمل (YYYY-MM-DD)',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // وقت البدء ووقت الانتهاء
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: startTimeCtrl,
                              decoration: InputDecoration(
                                labelText: 'وقت البدء (صباحاً)',
                                prefixIcon: const Icon(Icons.access_time_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: endTimeCtrl,
                              decoration: InputDecoration(
                                labelText: 'وقت الانتهاء (مساءً)',
                                prefixIcon: const Icon(Icons.timelapse_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // حالة الموقع
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: InputDecoration(
                          labelText: 'حالة المشروع الحالية',
                          prefixIcon: const Icon(Icons.flag_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('نشط وقيد العمل (Active)')),
                          DropdownMenuItem(value: 'completed', child: Text('مكتمل ومنجز (Completed)')),
                          DropdownMenuItem(value: 'halted', child: Text('متوقف مؤقتاً (Halted)')),
                          DropdownMenuItem(value: 'cancelled', child: Text('ملغي ومؤرشف (Cancelled)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => status = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // وصف وتوجيهات المشروع
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'وصف نطاق العمل والملاحظات',
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
                label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة الموقع'),
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
                    'status': status,
                    if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                  };

                  final ok = await context.read<ManagementProvider>().saveSite(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'تم تحديث بيانات الموقع بنجاح.' : 'تم إضافة الموقع بنجاح.'),
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

  // ==================== حوار حذف أو أرشفة الموقع ====================
  void _confirmDeleteOrCancelSite(SiteModel site) {
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
              Text('خيارات حذف / أرشفة الموقع'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الموقع: "${site.name}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              const Text(
                'يمكنك أرشفة الموقع (تحويل الحالة إلى ملغي مع حفظ السجلات التاريخية) أو الحذف النهائي:',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warningColor),
              icon: const Icon(Icons.archive_outlined, size: 16),
              label: const Text('أرشفة فقط (ملغي)'),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().cancelSite(site.id);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت أرشفة الموقع بنجاح.'), backgroundColor: AppTheme.successColor),
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
                final ok = await context.read<ManagementProvider>().deleteSite(site.id);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الموقع نهائياً.'), backgroundColor: AppTheme.successColor),
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
        title: const Text('مواقع العمل والمشاريع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث المواقع',
            onPressed: () => prov.fetchSites(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
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
              message: 'اضغط على زر الإضافة أدناه لإنشاء أول موقع عمل في المنظومة.',
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
                                  if (site.clientName != null && site.clientName!.isNotEmpty) ...[
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
                        if (site.location != null && site.location!.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  site.location!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (site.workDate != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                'تاريخ البدء: ${site.workDate}  •  ساعات العمل: ${site.startTime ?? "--"} إلى ${site.endTime ?? "--"}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ],
                        if (site.description != null && site.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            site.description!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('تعديل الموقع'),
                              onPressed: () => _showSiteDialog(site),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.dangerColor),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('حذف / أرشفة'),
                              onPressed: () => _confirmDeleteOrCancelSite(site),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_sites_screen',
        onPressed: () => _showSiteDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة موقع جديد'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }
}
