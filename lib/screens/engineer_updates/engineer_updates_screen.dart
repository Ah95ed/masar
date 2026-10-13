import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class EngineerUpdatesScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const EngineerUpdatesScreen({super.key, required this.api, this.drawer});

  @override
  State<EngineerUpdatesScreen> createState() => _EngineerUpdatesScreenState();
}

class _EngineerUpdatesScreenState extends State<EngineerUpdatesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
      context.read<ReportsProvider>().fetchReports();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Task _enrichTask(Task t, ReportsProvider reportsProv) {
    if (t.workersCount > 0 && t.temperature != null) {
      return t;
    }
    // Enrich with site report data if available
    try {
      final rep = reportsProv.reports.firstWhere((r) => r.siteId == t.siteId);
      return t.copyWith(
        workersCount: t.workersCount > 0 ? t.workersCount : rep.workersCount,
        machineryCount: t.machineryCount > 0 ? t.machineryCount : rep.machineryCount,
        temperature: t.temperature ?? rep.temperature,
        weather: t.weather ?? rep.weather,
        updatedByName: (t.updatedByName != null && t.updatedByName!.trim().isNotEmpty)
            ? t.updatedByName
            : rep.engineerName,
      );
    } catch (_) {
      return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final tasksProv = context.watch<TasksProvider>();
    final reportsProv = context.watch<ReportsProvider>();
    final allTasks = tasksProv.tasks.map((t) => _enrichTask(t, reportsProv)).toList();
    final filteredTasks = tasksProv.filteredTasks.map((t) => _enrichTask(t, reportsProv)).toList();

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('تحديثات المهندسين الميدانية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              tasksProv.fetchTasks();
              reportsProv.fetchReports();
            },
          ),
        ],
      ),
      body: tasksProv.isLoading && allTasks.isEmpty
          ? const LoadingState(message: 'جاري تحميل سجل تحديثات المهندسين...')
          : tasksProv.error != null && allTasks.isEmpty
              ? ErrorState(message: tasksProv.error!, onRetry: () => tasksProv.fetchTasks())
              : RefreshIndicator(
                  color: AppTheme.primaryTeal,
                  onRefresh: () async {
                    await tasksProv.fetchTasks();
                    await reportsProv.fetchReports();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // بطاقات المؤشرات السريعة في الأعلى
                      _buildSummaryMetrics(tasksProv, allTasks.length),
                      const SizedBox(height: 16),

                      // شريط البحث وفلاتر الحالة
                      _buildSearchAndFilters(tasksProv, allTasks.length),
                      const SizedBox(height: 16),

                      // عرض الجدول المرتب للشاشات الواسعة أو البطاقات للجوال
                      if (filteredTasks.isEmpty)
                        const EmptyState(
                          title: 'لا توجد تحديثات مطابقة',
                          message: 'لم يتم العثور على أي تحديثات للمهندسين مطابقة لمعايير البحث أو الفلتر.',
                          icon: Icons.rate_review_outlined,
                        )
                      else if (isWide)
                        _buildDataTable(filteredTasks)
                      else
                        ...filteredTasks.map((t) => _buildMobileCard(t)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryMetrics(TasksProvider tasksProv, int totalCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final cards = [
          _buildMetricCard(
            label: 'إجمالي التحديثات',
            value: '$totalCount',
            icon: Icons.assignment_outlined,
            accent: const Color(0xFF0284C7),
            bg: const Color(0xFFE0F2FE),
          ),
          _buildMetricCard(
            label: 'قيد التنفيذ',
            value: '${tasksProv.inProgressCount}',
            icon: Icons.pending_actions_rounded,
            accent: AppTheme.primaryTeal,
            bg: AppTheme.primaryTeal.withOpacity(0.12),
          ),
          _buildMetricCard(
            label: 'قيد المراجعة',
            value: '${tasksProv.reviewCount}',
            icon: Icons.hourglass_top_rounded,
            accent: const Color(0xFFF59E0B),
            bg: const Color(0xFFFEF3C7),
          ),
          _buildMetricCard(
            label: 'متوسط الإنجاز',
            value: '${tasksProv.avgProgress}%',
            icon: Icons.trending_up_rounded,
            accent: AppTheme.success,
            bg: AppTheme.success.withOpacity(0.12),
          ),
          _buildMetricCard(
            label: 'المهام المكتملة',
            value: '${tasksProv.doneCount}',
            icon: Icons.task_alt_rounded,
            accent: const Color(0xFF6366F1),
            bg: const Color(0xFFEEF2FF),
          ),
        ];

        if (isSmall) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards
                  .map((c) => Container(
                        width: 140,
                        margin: const EdgeInsets.only(left: 8),
                        child: c,
                      ))
                  .toList(),
            ),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(TasksProvider tasksProv, int totalCount) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: tasksProv.setSearch,
              decoration: InputDecoration(
                hintText: 'البحث باسم المهندس، المهمة، موقع العمل أو الملاحظة...',
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          tasksProv.setSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'كافة التحديثات ($totalCount)', tasksProv),
                  const SizedBox(width: 8),
                  _buildFilterChip('in_progress', 'قيد التنفيذ (${tasksProv.inProgressCount})', tasksProv),
                  const SizedBox(width: 8),
                  _buildFilterChip('review', 'قيد المراجعة (${tasksProv.reviewCount})', tasksProv),
                  const SizedBox(width: 8),
                  _buildFilterChip('done', 'المكتملة (${tasksProv.doneCount})', tasksProv),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, TasksProvider prov) {
    final isSelected = prov.filterStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) prov.setFilter(key);
      },
      selectedColor: AppTheme.primaryTeal.withOpacity(0.18),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primaryTeal : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryTeal : AppTheme.border,
      ),
    );
  }

  // ترتيب الجدول للشاشات الكبيرة (Desktop / Tablet)
  Widget _buildDataTable(List<Task> tasks) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 74,
          columnSpacing: 22,
          horizontalMargin: 16,
          columns: const [
            DataColumn(
              label: Text(
                'المهندس المسئول',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            DataColumn(
              label: Text(
                'المهمة وموقع العمل',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            DataColumn(
              label: Text(
                'نسبة الإنجاز والحالة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            DataColumn(
              label: Text(
                'العمال والآليات',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            DataColumn(
              label: Text(
                'الطقس والحرارة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            DataColumn(
              label: Text(
                'الملاحظة الميدانية',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            DataColumn(
              label: Text(
                'تاريخ التحديث',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ],
          rows: tasks.map((t) {
            return DataRow(
              cells: [
                // 1. المهندس المسئول
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.15),
                        child: const Icon(Icons.person, color: AppTheme.primaryTeal, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.engineerName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text(
                            'المشرف الميداني',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. المهمة وموقع العمل
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.apartment_rounded, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                t.siteName ?? 'الموقع #${t.siteId}',
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. نسبة الإنجاز والحالة
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusBadge(t.status, t.statusLabel),
                            Text(
                              '${t.progress}%',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: t.progress / 100.0,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              t.progress == 100 ? AppTheme.success : AppTheme.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. العمال والآليات
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              '${t.workersCount} عمال',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.precision_manufacturing_rounded, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '${t.machineryCount} آليات',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. الطقس والحرارة
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wb_sunny_outlined, size: 13, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              t.weather ?? 'مشمس',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.thermostat_outlined, size: 13, color: Colors.red),
                            const SizedBox(width: 2),
                            Text(
                              t.temperature != null ? '${t.temperature}°C' : '--',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 6. الملاحظة الميدانية
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      t.effectiveNote,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // 7. تاريخ التحديث
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        t.createdAt ?? 'اليوم',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // عرض بطاقات الجوال للشاشات الصغيرة
  Widget _buildMobileCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة: المهندس والحالة
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.15),
                  child: const Icon(Icons.person, color: AppTheme.primaryTeal, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.engineerName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        task.siteName ?? 'الموقع #${task.siteId}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(task.status, task.statusLabel),
              ],
            ),
            const SizedBox(height: 10),

            // عنوان المهمة
            Text(
              task.title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // شريط نسبة الإنجاز
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progress / 100.0,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.progress == 100 ? AppTheme.success : AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${task.progress}%',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // مؤشرات: العمال، الآليات، الطقس، الحرارة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMobileChip(
                    icon: Icons.groups_rounded,
                    label: '${task.workersCount} عمال',
                    color: const Color(0xFF0284C7),
                  ),
                  _buildMobileChip(
                    icon: Icons.precision_manufacturing_rounded,
                    label: '${task.machineryCount} آليات',
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildMobileChip(
                    icon: Icons.wb_sunny_outlined,
                    label: task.weather ?? 'مشمس',
                    color: Colors.orange,
                  ),
                  _buildMobileChip(
                    icon: Icons.thermostat_outlined,
                    label: task.temperature != null ? '${task.temperature}°C' : '--',
                    color: Colors.red,
                  ),
                ],
              ),
            ),

            // الملاحظة الميدانية
            if (task.effectiveNote != '-') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.effectiveNote,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // التاريخ في الأسفل
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                const Icon(Icons.access_time, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  task.createdAt ?? 'اليوم',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color bg = AppTheme.border;
    Color fg = AppTheme.textSecondary;

    switch (status.toLowerCase()) {
      case 'done':
      case 'completed':
        bg = AppTheme.successLight;
        fg = AppTheme.success;
        break;
      case 'in_progress':
        bg = AppTheme.primaryTeal.withOpacity(0.12);
        fg = AppTheme.primaryTeal;
        break;
      case 'review':
        bg = AppTheme.warningLight;
        fg = AppTheme.warning;
        break;
      case 'cancelled':
        bg = AppTheme.dangerLight;
        fg = AppTheme.danger;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
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
