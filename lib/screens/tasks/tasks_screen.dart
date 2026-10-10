import 'package:open_filex/open_filex.dart';
import '../../services/excel_service.dart';
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

  
  Future<void> _exportTasksToExcel(List<Task> tasks) async {
    if (tasks.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد خطط عمل لتصديرها', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kAmber,
        ),
      );
      return;
    }

    if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إنشاء وتصدير ملف Excel...', style: TextStyle(fontFamily: 'Cairo')),
        duration: Duration(seconds: 1),
      ),
    );

    final path = await ExcelService.instance.exportTasksToExcel(tasks);
    if (!mounted) return;

    if (path != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تصدير ${tasks.length} خطة عمل بنجاح!', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kGreen,
          action: SnackBarAction(
            label: 'فتح الملف',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(path),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تصدير الملف', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
  }

  Future<void> _importTasksFromExcel() async {
    try {
      final parsed = await ExcelService.instance.importTasksFromExcel();
      if (!mounted || parsed == null) return;

      if (parsed.isEmpty) {
        if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على أي خطط عمل في الملف أو الأعمدة غير متطابقة', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: kAmber,
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد استيراد خطط العمل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تم قراءة ${parsed.length} خطة عمل من ملف Excel بنجاح.', style: const TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              const Text('هل تريد استيرادها وحفظها في قاعدة البيانات الآن؟', style: TextStyle(fontFamily: 'Cairo', color: kMuted)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kPaper, borderRadius: BorderRadius.circular(6)),
                child: Text('عينة: ""', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
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
      final tasksProvider = context.read<TasksProvider>();
      int successCount = 0;
      for (final p in parsed) {
        try {
          await widget.api.post('work-plan-save', {
            'id': 0,
            'site_id': p['site_id'] ?? 1,
            'title': p['title'],
            'description': p['description'] ?? '',
            'assigned_to': p['assigned_to'] ?? 0,
            'is_broadcast': p['is_broadcast'] ?? false,
            'priority': p['priority'] ?? 'medium',
          });
          successCount++;
        } catch (_) {}
      }

      await tasksProvider.fetchTasks();
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('تم استيراد $successCount من أصل ${parsed.length} خطة بنجاح!', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء قراءة الملف: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
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
      if (!mounted) return;
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
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'تصدير إكسل',
              onPressed: () => _exportTasksToExcel(tasks),
            ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: 'استيراد إكسل',
              onPressed: () => _importTasksFromExcel(),
            ),
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
                    Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _exportTasksToExcel(prov.filteredTasks),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGreen,
                  side: const BorderSide(color: kGreen),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('تصدير إكسل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                onPressed: () => _importTasksFromExcel(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kCyan,
                  side: const BorderSide(color: kCyan),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 16),
                label: const Text('استيراد إكسل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: () => _openForm(),
                style: FilledButton.styleFrom(backgroundColor: kInk),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ خطة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = 950.0;
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
                        Expanded(flex: 30, child: Text('المهمة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 20, child: Text('الموقع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 20, child: Text('المهندس', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 15, child: Text('الأولوية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 15, child: Text('الحالة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 20, child: Text('التقدم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk))),
                        Expanded(flex: 20, child: Align(alignment: AlignmentDirectional.centerEnd, child: Text('الإجراءات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: kLine),
                  ...tasks.map((t) {
                    final isDone = t.status == 'done' || t.status == 'completed';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: kLine, width: 0.8)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 30,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    t.title,
                                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: kInk),
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
                          Expanded(
                            flex: 20,
                            child: Text(
                              t.siteName ?? 'الموقع #',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Text(
                              t.assignedToName ?? 'غير معين',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 15,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: _buildPriorityPill(t.priority),
                            ),
                          ),
                          Expanded(
                            flex: 15,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Pill(
                                text: t.statusLabel,
                                type: isDone ? PillType.success : PillType.warning,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Row(
                              children: [
                                Expanded(
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
                                Text(
                                  '%',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: kInk),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Row(
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