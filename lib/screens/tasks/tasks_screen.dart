import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const TasksScreen({super.key, required this.api, this.drawer});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
    });
  }

  Future<void> _openForm({Task? item}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(api: widget.api, item: item),
      ),
    );

    if (saved == true && mounted) {
      await context.read<TasksProvider>().fetchTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? 'تم إنشاء خطة العمل بنجاح' : 'تم تحديث خطة العمل بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _cancelTask(Task task) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'إلغاء خطة العمل',
      message: 'هل أنت متأكد من رغبتك في إلغاء خطة العمل "${task.title}"؟',
      confirmText: 'إلغاء الخطة',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    final success = await context.read<TasksProvider>().cancelTask(task.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء خطة العمل بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksProv = context.watch<TasksProvider>();
    final tasks = tasksProv.filteredTasks;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('خطط العمل والتوجيهات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'إضافة خطة عمل',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: tasksProv.isLoading && tasksProv.tasks.isEmpty
          ? const LoadingState(message: 'جاري تحميل خطط العمل...')
          : tasksProv.error != null && tasksProv.tasks.isEmpty
              ? ErrorState(message: tasksProv.error!, onRetry: () => tasksProv.fetchTasks())
              : RefreshIndicator(
                  onRefresh: () => tasksProv.fetchTasks(),
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(tasksProv),
                      Expanded(
                        child: tasks.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد خطط عمل',
                                message: 'لم يتم العثور على أي مهام تطابق معايير البحث',
                                icon: Icons.assignment_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return _buildTaskTile(task);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFiltersHeader(TasksProvider prov) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => prov.setSearch(v),
            decoration: const InputDecoration(
              hintText: 'بحث بعنوان المهمة، الموقع، المهندس...',
              prefixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('all', 'الكل (${prov.tasks.length})', prov),
                _buildStatusChip('pending', 'قيد الانتظار', prov),
                _buildStatusChip('in_progress', 'قيد التنفيذ', prov),
                _buildStatusChip('review', 'قيد المراجعة', prov),
                _buildStatusChip('done', 'مكتملة', prov),
                _buildStatusChip('cancelled', 'ملغاة', prov),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, TasksProvider prov) {
    final isSelected = prov.filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    final isDone = task.status == 'done' || task.status == 'completed';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      margin: const EdgeInsets.only(bottom: 8),
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
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  task.siteName ?? 'الموقع #${task.siteId}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  task.assignedToName ?? 'غير محدد',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
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
            if (!isDone) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    onPressed: () => _openForm(item: task),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: AppTheme.danger),
                    label: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.danger)),
                    onPressed: () => _cancelTask(task),
                  ),
                ],
              ),
            ],
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
        return AppTheme.textSecondary;
    }
  }
}
