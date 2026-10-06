import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/report.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  final AdminApi api;

  const ReportsScreen({super.key, required this.api});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Report> _reports = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ القاعدة الذهبية: جلب البيانات دائماً من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('reports');
      if (!mounted) return;
      setState(() {
        _reports = (res as List).map((e) => Report.fromJson(e)).toList();
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
        _error = 'حدث خطأ أثناء تحميل التقارير';
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(Report report) async {
    final reviewed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(api: widget.api, reportId: report.id),
      ),
    );

    // ✅ إعادة التحميل التلقائي بعد اعتماد أو رفض التقرير
    if (reviewed == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حالة التقرير بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  List<Report> get _filteredReports {
    if (_filterStatus == 'all') return _reports;
    return _reports.where((r) => r.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير اليومية الميدانية'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل التقارير اليومية...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredReports.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد تقارير مطابقة',
                                message: 'لم يتم العثور على أي تقارير بالحالة المحددة',
                                icon: Icons.description_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredReports.length,
                                itemBuilder: (context, index) {
                                  final report = _filteredReports[index];
                                  return _buildReportCard(report);
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip('all', 'الكل ()'),
            _buildStatusChip('submitted', 'بانتظار الاعتماد'),
            _buildStatusChip('approved', 'معتمدة'),
            _buildStatusChip('rejected', 'مرفوضة'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
        selected: isSelected,
        selectedColor: AppTheme.primaryDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _filterStatus = status),
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    Color statusBg = AppTheme.border;
    Color statusFg = AppTheme.textSecondary;
    String statusLabel = report.status;

    if (report.status == 'approved') {
      statusBg = AppTheme.successLight;
      statusFg = AppTheme.success;
      statusLabel = 'معتمد';
    } else if (report.status == 'rejected') {
      statusBg = AppTheme.dangerLight;
      statusFg = AppTheme.danger;
      statusLabel = 'مرفوض';
    } else if (report.status == 'submitted') {
      statusBg = AppTheme.warningLight;
      statusFg = AppTheme.warning;
      statusLabel = 'بانتظار الاعتماد';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(report),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.siteName ?? 'الموقع #',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    report.engineerName ?? 'مهندس الموقع',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    report.reportDate,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              if (report.workDone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  report.workDone,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإنجاز: %',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'مراجعة التفاصيل',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.primaryTeal),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 11, color: AppTheme.primaryTeal),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}