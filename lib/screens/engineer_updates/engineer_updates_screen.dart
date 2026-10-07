import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksProv = context.watch<TasksProvider>();
    final allTasks = tasksProv.tasks;
    final filteredTasks = tasksProv.filteredTasks;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('تحديثات المهندسين الميدانية'),
      ),
      body: tasksProv.isLoading && allTasks.isEmpty
          ? const LoadingState(message: 'جاري تحميل سجل تحديثات المهندسين...')
          : tasksProv.error != null && allTasks.isEmpty
              ? ErrorState(message: tasksProv.error!, onRetry: () => tasksProv.fetchTasks())
              : RefreshIndicator(
                  color: AppTheme.primaryTeal,
                  onRefresh: () => tasksProv.fetchTasks(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // بطاقات المؤشرات السريعة
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'قيد التنفيذ',
                              value: '${tasksProv.inProgressCount}',
                              icon: Icons.pending_actions_rounded,
                              accent: AppTheme.primaryTeal,
                              bg: AppTheme.primaryTeal.withOpacity(0.12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'متوسط الإنجاز',
                              value: '${tasksProv.avgProgress}%',
                              icon: Icons.trending_up_rounded,
                              accent: AppTheme.success,
                              bg: AppTheme.success.withOpacity(0.12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'المكتملة',
                              value: '${tasksProv.doneCount}',
                              icon: Icons.task_alt_rounded,
                              accent: const Color(0xFF6366F1),
                              bg: const Color(0xFFEEF2FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // فلاتر الحالة
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'كافة التحديثات (${allTasks.length})', tasksProv),
                            const SizedBox(width: 8),
                            _buildFilterChip('in_progress', 'قيد التنفيذ (${tasksProv.inProgressCount})', tasksProv),
                            const SizedBox(width: 8),
                            _buildFilterChip('review', 'قيد المراجعة (${tasksProv.reviewCount})', tasksProv),
                            const SizedBox(width: 8),
                            _buildFilterChip('done', 'المكتملة (${tasksProv.doneCount})', tasksProv),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (filteredTasks.isEmpty)
                        const EmptyState(
                          title: 'لا توجد تحديثات',
                          message: 'لم يتم العثور على تحديثات مهندسين مطابقة للفلتر المحدد.',
                          icon: Icons.rate_review_outlined,
                        )
                      else
                        ...filteredTasks.map((t) => _buildTaskUpdateCard(t)),
                    ],
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
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

  Widget _buildTaskUpdateCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  task.siteName ?? 'الموقع #${task.siteId}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  task.assignedToName ?? 'غير محدد',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
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
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
      case 'completed':
        return AppTheme.success;
      case 'in_progress':
        return AppTheme.primaryTeal;
      case 'review':
        return AppTheme.warning;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.textMuted;
    }
  }
}
