import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/report_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

/// شاشة تدقيق ومراجعة التقارير اليومية (اعتماد، رفض، تعديل، وحذف)
class ReportsReviewScreen extends StatefulWidget {
  const ReportsReviewScreen({super.key});

  @override
  State<ReportsReviewScreen> createState() => _ReportsReviewScreenState();
}

class _ReportsReviewScreenState extends State<ReportsReviewScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().fetchReports();
    });
  }

  void _onFilterChanged(String status) {
    setState(() => _selectedFilter = status);
    context.read<ManagementProvider>().fetchReports(status: status);
  }

  // ==================== حوار تعديل بيانات التقرير ====================
  void _showEditReportDialog(ReportModel report) {
    final formKey = GlobalKey<FormState>();
    final workDoneCtrl = TextEditingController(text: report.workDone);
    final workersCtrl = TextEditingController(text: report.workersCount.toString());
    final machineryCtrl = TextEditingController(text: report.machineryCount.toString());
    final progressCtrl = TextEditingController(text: report.progressPercent.toString());
    final issuesCtrl = TextEditingController(text: report.issues);
    final materialsCtrl = TextEditingController(text: report.materialsUsed);
    final safetyCtrl = TextEditingController(text: report.safetyNotes);
    final adminNotesCtrl = TextEditingController(text: report.adminNotes);
    String status = report.status;

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
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 10),
                Text('تعديل التقرير اليومي #${report.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الأعمال المنجزة
                      TextFormField(
                        controller: workDoneCtrl,
                        style: const TextStyle(fontSize: 12.5),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'الأعمال المنجزة وسير التنفيذ *',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),

                      // العمال والآليات ونسبة الإنجاز
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: workersCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'العمالة',
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              controller: machineryCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'الآليات',
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              controller: progressCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'الإنجاز %',
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // المشاكل والمعوقات
                      TextFormField(
                        controller: issuesCtrl,
                        style: const TextStyle(fontSize: 12.5),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'المعوقات والمشاكل الفنية (إن وجدت)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // المواد المستهلكة
                      TextFormField(
                        controller: materialsCtrl,
                        style: const TextStyle(fontSize: 12.5),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'المواد والخامات المستهلكة',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ملاحظات السلامة
                      TextFormField(
                        controller: safetyCtrl,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات السلامة المهنية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // حالة التقرير
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: status,
                        decoration: InputDecoration(
                          labelText: 'حالة التقرير',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'pending_approval', child: Text('بانتظار الاعتماد (Pending)')),
                          DropdownMenuItem(value: 'approved', child: Text('معتمد ومقفل (Approved)')),
                          DropdownMenuItem(value: 'rejected', child: Text('مرفوض للمراجعة (Rejected)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => status = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // توجيهات وملاحظات الإدارة
                      TextFormField(
                        controller: adminNotesCtrl,
                        style: const TextStyle(fontSize: 12.5),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات وتوجيهات المدير العام',
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
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ التعديلات'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    'id': report.id,
                    'report_id': report.id,
                    'work_done': workDoneCtrl.text.trim(),
                    'workers_count': int.tryParse(workersCtrl.text) ?? report.workersCount,
                    'machinery_count': int.tryParse(machineryCtrl.text) ?? report.machineryCount,
                    'progress_percent': int.tryParse(progressCtrl.text) ?? report.progressPercent,
                    'issues': issuesCtrl.text.trim(),
                    'materials_used': materialsCtrl.text.trim(),
                    'safety_notes': safetyCtrl.text.trim(),
                    'admin_notes': adminNotesCtrl.text.trim(),
                    'status': status,
                  };

                  final ok = await context.read<ManagementProvider>().updateReport(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تعديل التقرير بنجاح.'), backgroundColor: AppTheme.successColor),
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

  // ==================== حوار تأكيد حذف التقرير ====================
  void _confirmDeleteReport(ReportModel report) {
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
              Text('حذف التقرير اليومي'),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف التقرير #${report.id} الخاص بمشروع "${report.siteName}"؟\nسيتم حذف سجل التقرير وكافة بيانات المصروفات المرتبطة به نهائياً.',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor, foregroundColor: Colors.white),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('تأكيد الحذف'),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().deleteReport(report.id ?? 0);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف التقرير بنجاح.'), backgroundColor: AppTheme.successColor),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== تفاصيل التقرير والإيصالات ====================
  void _openReportDetails(ReportModel summaryReport) async {
    final prov = context.read<ManagementProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<ReportModel?>(
        future: prov.getReportDetails(summaryReport.id ?? 0),
        builder: (context, snapshot) {
          final report = snapshot.data ?? summaryReport;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقرير #${report.id ?? ""} • ${report.siteName ?? "موقع العمل"}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'إعداد: ${report.engineerName ?? "المهندس الميداني"} • التاريخ: ${report.reportDate}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ملخص التنفيذ
                          const Text('الأعمال المنجزة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(report.workDone, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155))),
                          const SizedBox(height: 14),

                          // العمال والآليات
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('العمالة بالموقع', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text('${report.workersCount} عامل', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                Container(height: 24, width: 1, color: Colors.grey.shade300),
                                Column(
                                  children: [
                                    const Text('الآليات العاملة', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text('${report.machineryCount} معدة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                Container(height: 24, width: 1, color: Colors.grey.shade300),
                                Column(
                                  children: [
                                    const Text('نسبة الإنجاز', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text('${report.progressPercent}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0284C7))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // المصروفات
                          const Text('مصروفات التقرير والمشتريات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          if (report.expenses.isEmpty)
                            const Text('لا توجد مصروفات مسجلة بهذا التقرير', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
                          else
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  ...report.expenses.map((e) => ListTile(
                                        dense: true,
                                        title: Text(e.itemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        subtitle: Text('${e.quantity} × ${ArabicHelpers.formatCurrency(e.unitPrice)} (${e.category})'),
                                        trailing: Text(
                                          ArabicHelpers.formatCurrency(e.total),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                        ),
                                      )),
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('الإجمالي العام للمصروفات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(
                                          ArabicHelpers.formatCurrency(report.totalExpenses),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // الإيصالات والمرفقات
                          const Text('إيصالات الصرف ومستندات الفواتير:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          if (report.receipts.isEmpty)
                            const Text('لم يتم إرفاق صور إيصالات', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: report.receipts.map((r) {
                                return InkWell(
                                  onTap: () {
                                    _showReceiptViewer(r.fileUrl, r.fileName);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 6),
                                        Text(r.fileName ?? 'إيصال مرفق', style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 16),

                          if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ملاحظات الإدارة المسجلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                                  const SizedBox(height: 4),
                                  Text(report.adminNotes!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // أزرار العمليات (تعديل وحذف)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.dangerColor),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('حذف التقرير'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteReport(report);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFF0F172A)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('تعديل التقرير'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditReportDialog(report);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // أزرار المراجعة والاعتماد
                  if (report.isApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('تم اعتماد التقرير رسمياً وترحيل قيوده المالية.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.dangerColor,
                              side: const BorderSide(color: AppTheme.dangerColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('رفض التقرير'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showReviewDecisionDialog(report, 'rejected');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('اعتماد التقرير'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showReviewDecisionDialog(report, 'approved');
                            },
                          ),
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

  void _showReceiptViewer(String url, String? name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(name ?? 'معاينة الإيصال', style: const TextStyle(fontSize: 14)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('تعذر تحميل صورة الإيصال'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDecisionDialog(ReportModel report, String decision) {
    final notesCtrl = TextEditingController();
    final isApprove = decision == 'approved';

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isApprove ? Icons.verified_rounded : Icons.cancel_rounded, color: isApprove ? const Color(0xFF10B981) : AppTheme.dangerColor),
              const SizedBox(width: 8),
              Text(isApprove ? 'اعتماد التقرير وترحيل القيود' : 'رفض التقرير وإعادته'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApprove
                    ? 'سيتم اعتماد التقرير وإقفاله رسمياً، مع توليد قيد اليومية المحاسبي للمصروفات المرتبطة تلقائياً.'
                    : 'سيتم تحويل حالة التقرير إلى مرفوض مع إشعار المهندس بالملاحظات لتعديله.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات وتوجيهات المدير (اختياري)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isApprove ? const Color(0xFF10B981) : AppTheme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().reviewReport(
                      reportId: report.id ?? 0,
                      decision: decision,
                      adminNotes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    );
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isApprove ? 'تم اعتماد التقرير بنجاح وتوليد القيود المالية.' : 'تم رفض التقرير وإعادته.'),
                      backgroundColor: isApprove ? const Color(0xFF10B981) : AppTheme.dangerColor,
                    ),
                  );
                }
              },
              child: Text(isApprove ? 'تأكيد الاعتماد' : 'تأكيد الرفض'),
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
        title: const Text('تدقيق ومراجعة التقارير اليومية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () => prov.fetchReports(status: _selectedFilter),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التصفية
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('بانتظار الاعتماد', 'pending_approval'),
                const SizedBox(width: 8),
                _buildFilterChip('معتمدة', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('مرفوضة', 'rejected'),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (prov.reportsState == LoadingState.loading && prov.reports.isEmpty) {
                  return const LoadingWidget(message: 'جاري تحميل التقارير...');
                }

                if (prov.reportsState == LoadingState.error && prov.reports.isEmpty) {
                  return ErrorView(
                    message: prov.reportsError ?? 'تعذر تحميل التقارير',
                    onRetry: () => prov.fetchReports(status: _selectedFilter),
                  );
                }

                if (prov.reports.isEmpty) {
                  return EmptyView(
                    title: 'لا توجد تقارير في هذا القسم',
                    message: 'جميع التقارير اليومية الواردة من المهندسين ستظهر هنا للمراجعة والاعتماد.',
                    icon: Icons.assignment_turned_in_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => prov.fetchReports(status: _selectedFilter),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = prov.reports[index];

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openReportDetails(report),
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
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.description_rounded, color: Color(0xFF0F172A), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.siteName ?? 'مشروع مكسلوند',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'م. ${report.engineerName ?? "المهندس"}  •  ${report.reportDate}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: report.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  report.workDone,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'المصروفات: ${ArabicHelpers.formatCurrency(report.totalExpenses)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: 'تعديل التقرير',
                                      onPressed: () => _showEditReportDialog(report),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor),
                                      tooltip: 'حذف التقرير',
                                      onPressed: () => _confirmDeleteReport(report),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(value),
      selectedColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
