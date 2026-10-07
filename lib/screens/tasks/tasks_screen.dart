import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';
import '../updates/work_updates_screen.dart';
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
          backgroundColor: kGreen,
        ),
      );
    }
  }

  Future<void> _cancelTask(Task task) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'إلغاء خطة العمل',
      message: 'هل أنت متأكد من رغبتك في إلغاء خطة "${task.title}"؟',
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
          backgroundColor: kGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksProv = context.watch<TasksProvider>();
    final tasks = tasksProv.filteredTasks;
    final isWide = MediaQuery.of(context).size.width >= 850;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 25),
      onRefresh: () => tasksProv.fetchTasks(),
      child: Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          title: const Text('خطط العمل'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_task_rounded),
              tooltip: 'خطة جديدة',
              onPressed: () => _openForm(),
            ),
          ],
        ),
        body: StateView(
          loading: tasksProv.isLoading && tasksProv.tasks.isEmpty,
          error: tasksProv.error,
          empty: false,
          onRetry: () => tasksProv.fetchTasks(),
          child: RefreshIndicator(
            onRefresh: () => tasksProv.fetchTasks(),
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // رأس: خطط العمل + وصف + زر + خطة جديدة
                _buildHeaderBar(tasksProv),
                const SizedBox(height: 12),

                // فلاتر المهام
                _buildFilterChips(tasksProv),
                const SizedBox(height: 16),

                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('لا توجد خطط عمل مطابقة للبحث', style: TextStyle(fontFamily: 'Cairo', color: kMuted)),
                    ),
                  )
                else if (isWide)
                  _buildTasksTable(tasks)
                else
                  _buildTasksCards(tasks),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'tasks_fab',
          onPressed: () => _openForm(),
          backgroundColor: kInk,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(TasksProvider prov) {
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
                'خطط العمل والمهام الهندسية',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
              ),
              Text(
                'إصدار ومتابعة وتعميم خطط العمل بالمشاريع الميدانية',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: () => _openForm(),
            style: FilledButton.styleFrom(backgroundColor: kInk),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ خطة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(TasksProvider prov) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChoiceChip('all', 'الكل (${prov.tasks.length})', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('pending', 'قيد الانتظار', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('in_progress', 'قيد التنفيذ', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('review', 'قيد المراجعة', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('done', 'مكتملة', prov),
          const SizedBox(width: 8),
          _buildChoiceChip('cancelled', 'ملغية', prov),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String status, String label, TasksProvider prov) {
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

  Widget _buildTasksTable(List<Task> tasks) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kLine),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(kPaper),
          columns: const [
            DataColumn(label: Text('المهمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الموقع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المهندس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الأولوية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('التقدم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
          ],
          rows: tasks.map((t) {
            final isDone = t.status == 'done' || t.status == 'completed';

            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    Text(t.title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    if (t.isBroadcast) ...[
                      const SizedBox(width: 6),
                      const Pill.info(text: 'تعميم'),
                    ],
                  ],
                )),
                DataCell(Text(t.siteName ?? 'الموقع #${t.siteId}', style: const TextStyle(fontFamily: 'Cairo'))),
                DataCell(Text(t.assignedToName ?? 'غير معين', style: const TextStyle(fontFamily: 'Cairo'))),
                DataCell(_buildPriorityPill(t.priority)),
                DataCell(Pill(
                  text: t.statusLabel,
                  type: isDone ? PillType.success : PillType.warning,
                )),
                DataCell(Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: t.progress / 100.0,
                          minHeight: 6,
                          backgroundColor: kLine,
                          valueColor: AlwaysStoppedAnimation<Color>(isDone ? kGreen : kCyan),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${t.progress}%', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: kCyan),
                      tooltip: 'تعديل',
                      onPressed: () => _openForm(item: t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, size: 18, color: kInk),
                      tooltip: 'السجل',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WorkUpdatesScreen(api: widget.api, planId: t.id)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, size: 18, color: kRed),
                      tooltip: 'إلغاء',
                      onPressed: () => _cancelTask(t),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTasksCards(List<Task> tasks) {
    return Column(
      children: tasks.map((t) {
        final isDone = t.status == 'done' || t.status == 'completed';

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
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.title,
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (t.isBroadcast) ...[
                            const SizedBox(width: 6),
                            const Pill.info(text: 'تعميم'),
                          ],
                        ],
                      ),
                    ),
                    _buildPriorityPill(t.priority),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.business_outlined, size: 14, color: kMuted),
                    const SizedBox(width: 4),
                    Text(t.siteName ?? 'الموقع #${t.siteId}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted)),
                    const Spacer(),
                    const Icon(Icons.person_outline, size: 14, color: kMuted),
                    const SizedBox(width: 4),
                    Text(t.assignedToName ?? 'غير معين', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: t.progress / 100.0,
                          minHeight: 6,
                          backgroundColor: kLine,
                          valueColor: AlwaysStoppedAnimation<Color>(isDone ? kGreen : kCyan),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${t.progress}%', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: kInk)),
                    const SizedBox(width: 8),
                    Pill(text: t.statusLabel, type: isDone ? PillType.success : PillType.warning),
                  ],
                ),
                const Divider(height: 18, color: kLine),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openForm(item: t),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: kCyan),
                      label: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kCyan)),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WorkUpdatesScreen(api: widget.api, planId: t.id)),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 16, color: kInk),
                      label: const Text('السجل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kInk)),
                    ),
                    TextButton.icon(
                      onPressed: () => _cancelTask(t),
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: kRed),
                      label: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kRed)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriorityPill(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Pill.warning(text: 'عاجل');
      case 'high':
        return const Pill.warning(text: 'مرتفع');
      case 'medium':
        return const Pill.info(text: 'متوسط');
      default:
        return const Pill.neutral(text: 'منخفض');
    }
  }
}