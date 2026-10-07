import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/sites_provider.dart';
import '../../services/admin_api.dart';
import '../../services/session_manager.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';
import '../sites/site_form_screen.dart';
import '../tasks/task_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AdminApi api;
  final void Function(int tabIndex)? onNavigateTab;
  final Widget? drawer;

  const DashboardScreen({
    super.key,
    required this.api,
    this.onNavigateTab,
    this.drawer,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _lastRefreshTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    _lastRefreshTime = DateTime.now();
    await Future.wait([
      context.read<DashboardProvider>().fetchDashboard(),
      context.read<ReportsProvider>().fetchReports(),
      context.read<TasksProvider>().fetchTasks(),
      context.read<SitesProvider>().fetchSites(),
    ]);
  }

  Future<void> _silentRefresh() async {
    _lastRefreshTime = DateTime.now();
    await Future.wait([
      context.read<DashboardProvider>().refreshSilently(),
      context.read<ReportsProvider>().fetchReports(),
      context.read<TasksProvider>().fetchTasks(),
    ]);
  }

  String _formatArabicDate(DateTime date) {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName، ${date.day} $monthName ${date.year}';
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final dashProv = context.watch<DashboardProvider>();
    final reportsProv = context.watch<ReportsProvider>();
    final tasksProv = context.watch<TasksProvider>();
    final isWide = MediaQuery.of(context).size.width >= 850;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 20),
      onRefresh: _silentRefresh,
      child: Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          title: const Text('لوحة المدير'),
        ),
        body: StateView(
          loading: dashProv.isLoading && dashProv.data == null,
          error: dashProv.error,
          empty: false,
          onRetry: _loadAll,
          child: RefreshIndicator(
            onRefresh: _loadAll,
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStatsGrid(dashProv, isWide),
                const SizedBox(height: 20),
                _buildEngineersPerformanceChart(dashProv),
                const SizedBox(height: 20),
                _buildDailyEvaluationTable(dashProv),
                const SizedBox(height: 20),
                _buildQuickLinks(),
                const SizedBox(height: 20),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRecentReports(reportsProv)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRecentTasks(tasksProv)),
                    ],
                  )
                else ...[
                  _buildRecentReports(reportsProv),
                  const SizedBox(height: 16),
                  _buildRecentTasks(tasksProv),
                ],
                const SizedBox(height: 20),
                _buildEngineerUpdatesSection(tasksProv),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeader() {
    final user = SessionManager.instance.user;
    final fullName = user?['full_name']?.toString() ?? 'المدير العام';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kInk,
            child: Text(
              fullName.isNotEmpty ? fullName[0] : 'M',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة المدير — $fullName',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'متابعة المشاريع والتقارير وتوقيع الحركات',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ),
          Pill.info(
            text: _formatArabicDate(DateTime.now()),
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardProvider prov, bool isWide) {
    final timeStr = 'حتى ${_formatTime(_lastRefreshTime)}';
    final sitesVal = prov.activeSitesCount > 0 ? '${prov.activeSitesCount}' : prov.totalSites;
    final engineersVal = prov.engineersCount > 0 ? '${prov.engineersCount}' : '${prov.todayTopEngineers.length}';
    final machineryVal = prov.machineryCount > 0 ? '${prov.machineryCount}' : prov.totalMachinery;
    final pendingVal = prov.pendingReportsCount > 0 ? '${prov.pendingReportsCount}' : prov.pendingReports;

    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWide ? 1.55 : 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'المواقع النشطة',
          value: sitesVal,
          subtitle: timeStr,
          icon: Icons.location_on_rounded,
          color: kCyan,
          onTap: () => widget.onNavigateTab?.call(1),
        ),
        _buildStatCard(
          title: 'المهندسون',
          value: engineersVal,
          subtitle: timeStr,
          icon: Icons.people_alt_rounded,
          color: kGreen,
          onTap: () => widget.onNavigateTab?.call(6),
        ),
        _buildStatCard(
          title: 'الآليات',
          value: machineryVal,
          subtitle: timeStr,
          icon: Icons.precision_manufacturing_rounded,
          color: kAmber,
        ),
        _buildStatCard(
          title: 'تقارير بانتظار المراجعة',
          value: pendingVal,
          subtitle: timeStr,
          icon: Icons.assignment_late_outlined,
          color: kRed,
          onTap: () => widget.onNavigateTab?.call(3),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kLine),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngineersPerformanceChart(DashboardProvider prov) {
    final list = prov.todayTopEngineers;
    String topEng = 'لا توجد بيانات مسجلة';
    int topScore = 0;

    if (list.isNotEmpty) {
      final first = list.first as Map<String, dynamic>;
      topEng = first['full_name']?.toString() ?? 'مهندس';
      topScore = int.tryParse(first['score']?.toString() ?? '0') ?? 0;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'إنجاز المهندسين اليوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const Spacer(),
                if (list.isNotEmpty)
                  Pill.success(text: 'الأعلى: $topEng · $topScore%'),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'متوسط نسب الإنجاز المسجلة اليوم',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 16),

            if (list.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('لا توجد بيانات إنجاز مسجلة اليوم', style: TextStyle(fontFamily: 'Cairo', color: kMuted)),
                ),
              )
            else ...[
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) => const FlLine(color: kLine, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (val, _) => Text(
                            '${val.toInt()}%',
                            style: const TextStyle(fontSize: 10, color: kMuted),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < list.length) {
                              final eng = list[idx] as Map<String, dynamic>;
                              final name = (eng['full_name']?.toString() ?? '').split(' ').first;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  name,
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kInk),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(list.length, (idx) {
                      final item = list[idx] as Map<String, dynamic>;
                      final score = double.tryParse(item['score']?.toString() ?? '0') ?? 0.0;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: score,
                            color: kGreen,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...list.map((item) {
                final eng = item as Map<String, dynamic>;
                final name = eng['full_name']?.toString() ?? 'مهندس';
                final score = int.tryParse(eng['score']?.toString() ?? '0') ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          name,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score / 100.0,
                            minHeight: 8,
                            backgroundColor: kGreenPale,
                            valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$score%',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: kGreen),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildDailyEvaluationTable(DashboardProvider prov) {
    final list = prov.todayTopEngineers;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'تقييم الإنجاز اليومي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const Spacer(),
                const Pill.info(text: 'من 100'),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('لا توجد تقييمات منشورة لليوم', style: TextStyle(fontFamily: 'Cairo', color: kMuted)),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(kPaper),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('الترتيب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('المهندس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('التقييم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الأنشطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('مهام منجزة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(list.length, (idx) {
                    final eng = list[idx] as Map<String, dynamic>;
                    final name = eng['full_name']?.toString() ?? 'مهندس';
                    final score = eng['score']?.toString() ?? '0';
                    final acts = eng['activity_count']?.toString() ?? '0';
                    final tasks = eng['completed_tasks']?.toString() ?? '0';

                    return DataRow(
                      cells: [
                        DataCell(CircleAvatar(
                          radius: 12,
                          backgroundColor: idx == 0 ? kGreen : kPaper,
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: idx == 0 ? Colors.white : kInk,
                            ),
                          ),
                        )),
                        DataCell(Text(name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600))),
                        DataCell(Pill.success(text: '$score%')),
                        DataCell(Text(acts, style: const TextStyle(fontFamily: 'Cairo'))),
                        DataCell(Text(tasks, style: const TextStyle(fontFamily: 'Cairo'))),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickLinkButton(
            label: 'مراجعة التقارير',
            icon: Icons.bar_chart_rounded,
            color: kCyan,
            onTap: () => widget.onNavigateTab?.call(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickLinkButton(
            label: 'توقيع الحركات',
            icon: Icons.verified_outlined,
            color: kGreen,
            onTap: () => widget.onNavigateTab?.call(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickLinkButton(
            label: 'إضافة مسؤول قسم',
            icon: Icons.person_add_outlined,
            color: kInk,
            onTap: () => widget.onNavigateTab?.call(6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kLine),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReports(ReportsProvider prov) {
    final reports = prov.reports.take(5).toList();

    return Card(
      elevation: 0,
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
                const Text(
                  'آخر التقارير',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: kInk),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(3),
                  child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kCyan)),
                ),
              ],
            ),
            const Divider(height: 1, color: kLine),
            if (reports.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('لا توجد تقارير حالية', style: TextStyle(fontFamily: 'Cairo', color: kMuted))),
              )
            else
              ...reports.map((r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(r.siteName ?? 'موقع #${r.siteId}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${r.engineerName ?? "مهندس"} · ${r.reportDate}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted)),
                trailing: Pill(
                  text: r.statusLabel,
                  type: r.status == 'approved' ? PillType.success : (r.status == 'rejected' ? PillType.danger : PillType.warning),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasks(TasksProvider prov) {
    final tasks = prov.tasks.take(5).toList();

    return Card(
      elevation: 0,
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
                const Text(
                  'آخر المهام',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: kInk),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(2),
                  child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kCyan)),
                ),
              ],
            ),
            const Divider(height: 1, color: kLine),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('لا توجد مهام حالية', style: TextStyle(fontFamily: 'Cairo', color: kMuted))),
              )
            else
              ...tasks.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            t.title,
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${t.progress}%', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: kCyan)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.siteName ?? "الموقع"} · ${t.assignedToName ?? "غير معين"}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: t.progress / 100.0,
                        minHeight: 5,
                        backgroundColor: kLine,
                        valueColor: const AlwaysStoppedAnimation<Color>(kCyan),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineerUpdatesSection(TasksProvider prov) {
    final updates = prov.tasks.where((t) => t.progress > 0).take(6).toList();

    return Card(
      elevation: 0,
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
                const Text(
                  'تحديثات المهندسين',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: kInk),
                ),
                TextButton.icon(
                  onPressed: () => widget.onNavigateTab?.call(5),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('سجل التحديثات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 1, color: kLine),
            if (updates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('لا توجد تحديثات عمل حديثة', style: TextStyle(fontFamily: 'Cairo', color: kMuted))),
              )
            else
              ...updates.map((u) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: kCyanPale,
                  child: const Icon(Icons.engineering_outlined, size: 16, color: kCyan),
                ),
                title: Text(u.title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('${u.assignedToName ?? "مهندس"} · ${u.siteName ?? "موقع"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted)),
                trailing: Pill.success(text: '${u.progress}%'),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: kInk),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionTile(
              label: 'موقع جديد',
              icon: Icons.add_business_rounded,
              color: kInk,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SiteFormScreen(api: widget.api)),
                );
                if (mounted) context.read<SitesProvider>().fetchSites();
              },
            ),
            _buildActionTile(
              label: 'خطة عمل جديدة',
              icon: Icons.add_task_rounded,
              color: kCyan,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TaskFormScreen(api: widget.api)),
                );
                if (mounted) context.read<TasksProvider>().fetchTasks();
              },
            ),
            _buildActionTile(
              label: 'مراجعة التقارير',
              icon: Icons.rate_review_outlined,
              color: kAmber,
              onTap: () => widget.onNavigateTab?.call(3),
            ),
            _buildActionTile(
              label: 'توقيع الحركات',
              icon: Icons.draw_rounded,
              color: kGreen,
              onTap: () => widget.onNavigateTab?.call(4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.08),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
