import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/report.dart';
import '../../services/admin_api.dart';
import '../../services/excel_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';

class ReportDetailScreen extends StatefulWidget {
  final AdminApi api;
  final int reportId;

  const ReportDetailScreen({
    super.key,
    required this.api,
    required this.reportId,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Report? _report;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('reports', {'id': widget.reportId.toString()});
      if (!mounted) return;
      setState(() {
        _report = Report.fromJson(Map<String, dynamic>.from(res as Map));
        _notesCtrl.text = _report?.adminNotes ?? '';
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
        _error = 'حدث خطأ أثناء تحميل تفاصيل التقرير';
        _loading = false;
      });
    }
  }

  Future<void> _deleteReport() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'حذف التقرير اليومي',
      message: 'هل أنت متأكد من حذف التقرير #${widget.reportId} نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'نعم، حذف التقرير',
      cancelText: 'إلغاء',
      isDestructive: true,
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await widget.api.post('report-delete', {
        'report_id': widget.reportId,
        'id': widget.reportId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف التقرير بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حذف التقرير', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _reviewReport(String decision) async {
    setState(() => _submitting = true);

    try {
      await widget.api.post('report-review', {
        'report_id': widget.reportId,
        'decision': decision,
        'admin_notes': _notesCtrl.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت مراجعة هذا التقرير مسبقاً من قبل الإدارة',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.warning,
          ),
        );
        await _loadDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إرسال قرار الاعتماد', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _exportSingleReport() async {
    if (_report == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إنشاء ملف Excel للتقرير والمصروفات...', style: TextStyle(fontFamily: 'Cairo')),
        duration: Duration(seconds: 1),
      ),
    );

    final path = await ExcelService.instance.exportSingleReportToExcel(_report!);
    if (!mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تصدير التقرير #${_report!.id} بنجاح!', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
          action: SnackBarAction(
            label: 'فتح الملف',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(path),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تصدير التقرير', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير يومي #${widget.reportId}'),
        actions: [
          if (_report != null) ...[
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'تصدير التقرير (Excel)',
              onPressed: _exportSingleReport,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              tooltip: 'حذف التقرير',
              onPressed: _deleteReport,
            ),
          ],
        ],
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل التقرير والمرفقات...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _loadDetails)
              : _buildContent(),
    );
  }

  void _previewReceipt(ReportReceipt receipt) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Color(0xFF0EA5E9), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.originalName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (receipt.fileSizeLabel.isNotEmpty)
                            Text(
                              receipt.fileSizeLabel,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Flexible(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: receipt.isImage
                        ? CachedNetworkImage(
                            imageUrl: receipt.fullUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                            ),
                            errorWidget: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                                  SizedBox(height: 8),
                                  Text(
                                    'تعذر تحميل الصورة من الخادم',
                                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description_outlined, color: Color(0xFF0EA5E9), size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  receipt.originalName,
                                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ملف غير مدعوم للمعاينة المباشرة',
                                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white.withOpacity(0.7), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptsCard(List<ReportReceipt> receipts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('الوصولات والمستندات المرفقة (${receipts.length})'),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: receipts.isEmpty
                ? const Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'لا توجد وصولات أو مستندات مرفقة بهذا التقرير',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisExtent: 180,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: receipts.length,
                        itemBuilder: (context, index) {
                          final r = receipts[index];
                          return InkWell(
                            onTap: () => _previewReceipt(r),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                      child: r.isImage
                                          ? CachedNetworkImage(
                                              imageUrl: r.fullUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0EA5E9)),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (_, __, ___) => Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.receipt_outlined, color: Colors.grey, size: 36),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(Icons.description_outlined, color: Color(0xFF0EA5E9), size: 40),
                                            ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    color: Colors.white,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.originalName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              r.fileSizeLabel.isNotEmpty ? r.fileSizeLabel : 'معاينة',
                                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey),
                                            ),
                                            const Icon(Icons.zoom_in_rounded, size: 16, color: Color(0xFF0EA5E9)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final rep = _report!;
    final isPending = rep.status == 'submitted';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقة ملخص التقرير الأساسية
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة: اسم الموقع والحالة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryTeal, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rep.siteName ?? 'موقع العمل',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'الموقع #${rep.siteId}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(rep.status),
                  ],
                ),
                const SizedBox(height: 14),

                // شريط المهندس والتاريخ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.15),
                        child: const Icon(Icons.person, color: AppTheme.primaryTeal, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المهندس المشرف الذي أرسل التقرير:',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppTheme.textMuted),
                            ),
                            Text(
                              rep.engineerName ?? 'مهندس غير محدد',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            rep.reportDate,
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // بطاقات المؤشرات الميدانية (العمال، الآليات، الطقس، الحرارة)
                Row(
                  children: [
                    _buildMetricCard(
                      label: 'عدد العمال',
                      value: '${rep.workersCount} عامل',
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      label: 'عدد الآليات',
                      value: '${rep.machineryCount} آلية',
                      icon: Icons.precision_manufacturing_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      label: 'حالة الطقس',
                      value: rep.weather ?? 'مشمس',
                      icon: Icons.wb_sunny_outlined,
                      color: const Color(0xFFEAB308),
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      label: 'درجة الحرارة',
                      value: rep.temperature != null ? '${rep.temperature}°C' : '--',
                      icon: Icons.thermostat_outlined,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // شريط نسبة الإنجاز
                Row(
                  children: [
                    const Text(
                      'نسبة الإنجاز المحققة:',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${rep.progressPercent}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rep.progressPercent / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rep.progressPercent == 100 ? AppTheme.success : AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // الأعمال المنفذة
        _buildSectionTitle('الأعمال المنفذة'),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              rep.workDone.isNotEmpty ? rep.workDone : 'لا توجد تفاصيل مسجلة للأعمال',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // العوائق والمشاكل
        if (rep.issues != null && rep.issues!.isNotEmpty) ...[
          _buildSectionTitle('العوائق والمشاكل الميدانية'),
          Card(
            elevation: 0,
            color: AppTheme.dangerLight.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.danger),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                rep.issues!,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppTheme.danger, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // المواد المستخدمة
        if (rep.materialsUsed != null && rep.materialsUsed!.isNotEmpty) ...[
          _buildSectionTitle('المواد والتوريدات المستخدمة'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                rep.materialsUsed!,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // المصروفات اليومية
        if (rep.expenses.isNotEmpty) ...[
          _buildSectionTitle('المصروفات اليومية (${rep.expenses.length})'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rep.expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (ctx, i) {
                final ex = rep.expenses[i];
                return ListTile(
                  dense: true,
                  title: Text(ex.itemName, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                  subtitle: Text('الكمية: ${ex.quantity} • الفئة: ${ex.category}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  trailing: Text(
                    '${ex.total.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // الوصولات والمستندات
        _buildReceiptsCard(rep.receipts),
        const SizedBox(height: 16),

        // ملاحظات وقرار الإدارة
        _buildSectionTitle('ملاحظات وقرار الإدارة'),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات الإدارة / سبب الرفض أو التوجيه',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : () => _reviewReport('rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: const BorderSide(color: AppTheme.danger),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('رفض التقرير', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : () => _reviewReport('approved'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('اعتماد التقرير', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      rep.status == 'approved' ? 'تم اعتماد هذا التقرير رسمياً' : 'تم رفض هذا التقرير',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: rep.status == 'approved' ? AppTheme.success : AppTheme.danger,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppTheme.border;
    Color fg = AppTheme.textSecondary;
    String text = status;

    switch (status) {
      case 'submitted':
        bg = AppTheme.warningLight;
        fg = AppTheme.warning;
        text = 'قيد المراجعة';
        break;
      case 'approved':
        bg = AppTheme.successLight;
        fg = AppTheme.success;
        text = 'معتمد';
        break;
      case 'rejected':
        bg = AppTheme.dangerLight;
        fg = AppTheme.danger;
        text = 'مرفوض';
        break;
      default:
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
