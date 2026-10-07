import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/report.dart';
import '../../providers/reports_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const ReportsScreen({super.key, required this.api, this.drawer});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchReports();
    });
  }

  Future<void> _openDetail(Report report) async {
    final reviewed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(api: widget.api, reportId: report.id),
      ),
    );

    if (reviewed == true && mounted) {
      await context.read<ReportsProvider>().fetchReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProv = context.watch<ReportsProvider>();
    final reports = reportsProv.filteredReports;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('التقارير اليومية الميدانية'),
      ),
      body: reportsProv.isLoading && reportsProv.reports.isEmpty
          ? const LoadingState(message: 'جاري تحميل التقارير اليومية...')
          : reportsProv.error != null && reportsProv.reports.isEmpty
              ? ErrorState(message: reportsProv.error!, onRetry: () => reportsProv.fetchReports())
              : RefreshIndicator(
                  onRefresh: () => reportsProv.fetchReports(),
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFilterBar(reportsProv),
                      Expanded(
                        child: reports.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد تقارير',
                                message: 'لم يتم العثور على أي تقارير تطابق الفلتر المحدد',
                                icon: Icons.description_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: reports.length,
                                itemBuilder: (context, index) {
                                  final report = reports[index];
                                  return _buildReportTile(report);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterBar(ReportsProvider prov) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'الكل (${prov.reports.length})', prov),
            _buildFilterChip('submitted', 'بانتظار المراجعة (${prov.pendingCount})', prov),
            _buildFilterChip('approved', 'المعتمدة (${prov.approvedCount})', prov),
            _buildFilterChip('rejected', 'المرفوضة (${prov.rejectedCount})', prov),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label, ReportsProvider prov) {
    final isSelected = prov.filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => prov.setFilter(status),
        selectedColor: AppTheme.primaryDark,
        backgroundColor: Colors.grey.shade100,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      ),
    );
  }

  Widget _buildReportTile(Report report) {
    final hasExpenses = report.expenses.isNotEmpty;
    final hasReceipts = report.receipts.isNotEmpty;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openDetail(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.siteName ?? 'الموقع #${report.siteId}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(report.status),
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
                    report.engineerName ?? 'المهندس #${report.engineerId}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    report.reportDate,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.workDone,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (hasExpenses) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 3),
                          Text(
                            '${report.expenses.length} مصروف',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (hasReceipts) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, size: 12, color: Colors.purple.shade700),
                          const SizedBox(width: 3),
                          Text(
                            '${report.receipts.length} مرفق',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.purple.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  Text(
                    'نسبة الإنجاز: ${report.progressPercent}%',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left, size: 18, color: AppTheme.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.danger;
      case 'submitted':
      case 'pending':
      default:
        return AppTheme.warning;
    }
  }
}
