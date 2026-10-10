import 'package:open_filex/open_filex.dart';
import '../../services/excel_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/report.dart';
import '../../providers/reports_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;
  final String? initialStatus;

  const ReportsScreen({
    super.key,
    required this.api,
    this.drawer,
    this.initialStatus,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialStatus != null) {
        context.read<ReportsProvider>().setFilter(widget.initialStatus!);
      }
      context.read<ReportsProvider>().fetchReports();
    });
  }

  
  Future<void> _exportReportsToExcel(List<Report> reports) async {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد تقارير لتصديرها', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kAmber,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إنشاء وتصدير ملف Excel...', style: TextStyle(fontFamily: 'Cairo')),
        duration: Duration(seconds: 1),
      ),
    );

    final path = await ExcelService.instance.exportReportsToExcel(reports);
    if (!mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تصدير ${reports.length} تقرير بنجاح!', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kGreen,
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
          content: Text('تعذر تصدير الملف', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
  }

  Future<void> _importReportsFromExcel() async {
    try {
      final parsed = await ExcelService.instance.importReportsFromExcel();
      if (!mounted || parsed == null) return;

      if (parsed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على أي تقارير في الملف أو الأعمدة غير متطابقة', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: kAmber,
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('معاينة استيراد التقارير', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تم قراءة ${parsed.length} تقرير من ملف Excel بنجاح.', style: const TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              Text('عينة: ""', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted)),
              const SizedBox(height: 12),
              const Text('هل تريد حفظها ومزامنتها في النظام الآن؟', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: kGreen),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('اعتماد واستيراد', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final reportsProv = context.read<ReportsProvider>();
      int successCount = 0;

      for (final r in parsed) {
        try {
          await widget.api.post('report-save', {
            'report_date': r['report_date'],
            'site_id': r['site_id'],
            'work_progress': r['work_progress'],
            'workers_count': r['workers_count'],
            'machinery_count': r['machinery_count'],
            'work_done': r['work_done'],
            'issues': r['issues'] ?? '',
            'materials_used': r['materials_used'] ?? '',
          });
          successCount++;
        } catch (_) {}
      }

      await reportsProv.fetchReports();
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('تم استيراد $successCount من أصل ${parsed.length} تقرير بنجاح!', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء قراءة الملف: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
  }

  Future<void> _openDetail(Report report) async {
    final reviewed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(
          api: widget.api,
          reportId: report.id,
        ),
      ),
    );

    if (reviewed == true && mounted) {
      await context.read<ReportsProvider>().fetchReports();
    }
  }

  Future<void> _quickReview(Report report, String decision) async {
    final notesCtrl = TextEditingController();
    final isApprove = decision == 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'اعتماد التقرير اليومي' : 'رفض التقرير اليومي', style: const TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من ${isApprove ? "اعتماد" : "رفض"} تقرير موقع "${report.siteName}"؟', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'ملاحظات وتوجيهات المدير (اختياري)...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: isApprove ? kGreen : kRed),
            child: Text(isApprove ? 'اعتماد' : 'رفض', style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.api.post('report-review', {
        'report_id': report.id,
        'decision': decision,
        'admin_notes': notesCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApprove ? 'تم اعتماد التقرير بنجاح' : 'تم رفض التقرير', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: isApprove ? kGreen : kRed,
        ),
      );
      context.read<ReportsProvider>().fetchReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تنفيذ العملية: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProv = context.watch<ReportsProvider>();
    final reports = reportsProv.filteredReports;
    final isWide = MediaQuery.of(context).size.width >= 850;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 30),
      onRefresh: () => reportsProv.fetchReports(),
      child: Scaffold(
        drawer: widget.drawer,
                appBar: AppBar(
          title: const Text('التقارير اليومية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'تصدير إكسل',
              onPressed: () => _exportReportsToExcel(reports),
            ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: 'استيراد إكسل',
              onPressed: () => _importReportsFromExcel(),
            ),
          ],
        ),
        body: StateView(
          loading: reportsProv.isLoading && reportsProv.reports.isEmpty,
          error: reportsProv.error,
          empty: false,
          onRetry: () => reportsProv.fetchReports(),
          child: RefreshIndicator(
            onRefresh: () => reportsProv.fetchReports(),
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderBar(reportsProv),
                const SizedBox(height: 12),

                _buildFilterBar(reportsProv),
                const SizedBox(height: 16),

                if (reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('لا توجد تقارير تطابق الفلتر المحدد', style: TextStyle(fontFamily: 'Cairo', color: kMuted)),
                    ),
                  )
                else if (isWide)
                  _buildReportsTable(reports)
                else
                  _buildReportsCards(reports),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(ReportsProvider prov) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التقارير الميدانية والمراجعة الإدارية',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
              ),
              Text(
                'مراجعة واعتماد أو رفض تقارير الإنجاز اليومية المرفوعة من المهندسين',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
              ),
            ],
          ),
                    Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _exportReportsToExcel(prov.filteredReports),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGreen,
                  side: const BorderSide(color: kGreen),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('تصدير إكسل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                onPressed: () => _importReportsFromExcel(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kCyan,
                  side: const BorderSide(color: kCyan),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 16),
                label: const Text('استيراد إكسل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              if (prov.pendingCount > 0)
                Pill.warning(text: '${prov.pendingCount} بانتظار المراجعة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ReportsProvider prov) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'الكل (${prov.reports.length})', prov),
          const SizedBox(width: 8),
          _buildFilterChip('submitted', 'بانتظار المراجعة (${prov.pendingCount})', prov),
          const SizedBox(width: 8),
          _buildFilterChip('approved', 'المعتمدة (${prov.approvedCount})', prov),
          const SizedBox(width: 8),
          _buildFilterChip('rejected', 'المرفوضة (${prov.rejectedCount})', prov),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label, ReportsProvider prov) {
    final isSelected = prov.filterStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => prov.setFilter(status),
      selectedColor: kInk,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : kInk,
      ),
      side: BorderSide(color: isSelected ? kInk : kLine),
    );
  }

  Widget _buildReportsTable(List<Report> reports) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = 980.0;
        final tableWidth = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: kLine),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: kPaper,
                    child: const Row(
                      children: [
                        Expanded(flex: 22, child: Text('التاريخ والموقع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 16, child: Text('المهندس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 12, child: Text('الإنجاز', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 14, child: Text('العمال/الآليات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 14, child: Text('الحالة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 24, child: Text('ملخص العمل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 20, child: Align(alignment: AlignmentDirectional.centerEnd, child: Text('المراجعة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: kLine),
                  ...reports.map((report) {
                    final isSubmitted = report.status == 'submitted';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: kLine, width: 0.8)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 22,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report.reportDate, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk)),
                                Text(report.siteName ?? 'الموقع #', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 16,
                            child: Text(
                              report.engineerName ?? 'مهندس #',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text(
                              '%',
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12, color: kCyan),
                            ),
                          ),
                          Expanded(
                            flex: 14,
                            child: Text(
                              ' / ',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kInk),
                            ),
                          ),
                          Expanded(
                            flex: 14,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Pill(
                                text: report.statusLabel,
                                type: report.status == 'approved' ? PillType.success : (report.status == 'rejected' ? PillType.danger : PillType.warning),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 24,
                            child: Text(
                              report.workDone,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kInk),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                    label: const Text('معاينة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                                    onPressed: () => _openDetail(report),
                                  ),
                                  if (isSubmitted) ...[
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline_rounded, color: kGreen, size: 18),
                                      tooltip: 'اعتماد',
                                      onPressed: () => _quickReview(report, 'approved'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: kRed, size: 18),
                                      tooltip: 'رفض',
                                      onPressed: () => _quickReview(report, 'rejected'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildReportsCards(List<Report> reports) {
    return Column(
      children: reports.map((r) {
        final isSubmitted = r.status == 'submitted';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: kLine),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.siteName ?? 'الموقع #${r.siteId}',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
                    ),
                    Pill(
                      text: r.statusLabel,
                      type: r.status == 'approved' ? PillType.success : (r.status == 'rejected' ? PillType.danger : PillType.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: kMuted),
                    const SizedBox(width: 4),
                    Text(r.engineerName ?? 'مهندس #${r.engineerId}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted)),
                    const Spacer(),
                    const Icon(Icons.calendar_today_outlined, size: 12, color: kMuted),
                    const SizedBox(width: 4),
                    Text(r.reportDate, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('الإنجاز: ', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted)),
                    Text('${r.workProgress}%', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: kCyan)),
                    const SizedBox(width: 16),
                    const Text('العمال / الآليات: ', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted)),
                    Text('${r.manpowerCount} / ${r.machineryCount}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: kInk)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.workDone,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                ),
                const Divider(height: 18, color: kLine),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: kCyan),
                      label: const Text('معاينة التقرير', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kCyan)),
                      onPressed: () => _openDetail(r),
                    ),
                    if (isSubmitted) ...[
                      const SizedBox(width: 6),
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 16, color: kGreen),
                        label: const Text('اعتماد', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kGreen, fontWeight: FontWeight.bold)),
                        onPressed: () => _quickReview(r, 'approved'),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 16, color: kRed),
                        label: const Text('رفض', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kRed)),
                        onPressed: () => _quickReview(r, 'rejected'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}