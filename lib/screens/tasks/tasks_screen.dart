import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
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
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'all';
  String _searchQuery = '';

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
      final res = await widget.api.get('tasks');
      if (!mounted) return;
      setState(() {
        _tasks = (res as List).map((e) => Task.fromJson(e)).toList();
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
        _error = 'حدث خطأ أثناء تحميل خطط العمل';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Task? item}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(api: widget.api, item: item),
      ),
    );

    // ✅ إذا عاد النموذج بنجاح نعيد الجلب من السيرفر
    if (saved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? 'تم إصدار خطة العمل بنجاح' : 'تم تحديث خطة العمل بنجاح',
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
      message: 'هل أنت متأكد من إلغاء خطة العمل "${task.title}"؟',
      confirmText: 'إلغاء الخطة',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await widget.api.post('work-plan-cancel', {'task_id': task.id});
      if (!mounted) return;
      // ✅ إعادة جلب البيانات فوراً بعد استجابة السيرفر
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء خطة العمل بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  List<Task> get _filteredTasks {
    return _tasks.where((t) {
      final matchesStatus = _filterStatus == 'all' || t.status == _filterStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.siteName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('خطط العمل والتوجيهات'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'إضافة خطة عمل',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل خطط العمل...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredTasks.isEmpty
                            ? const EmptyState(
                                title: 'لا توجد مهام مطابقة',
                                message: 'قم بإضافة خطة عمل جديدة للموقع',
                                icon: Icons.assignment_late_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = _filteredTasks[index];
                                  return _buildTaskCard(task);
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

  Widget _buildFiltersHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'بحث في عنوان المهمة أو اسم الموقع...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('all', 'الكل (${_tasks.length})'),
                _buildStatusChip('pending', 'قيد الانتظار'),
                _buildStatusChip('in_progress', 'جارية'),
                _buildStatusChip('completed', 'مكتملة'),
                _buildStatusChip('cancelled', 'ملغية'),
              ],
            ),
          ),
        ],
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

  Widget _buildTaskCard(Task task) {
    Color priorityColor = AppTheme.info;
    String priorityText = 'عادية';

    switch (task.priority) {
      case 'urgent':
        priorityColor = AppTheme.danger;
        priorityText = 'حرجة وعاجلة';
        break;
      case 'high':
        priorityColor = AppTheme.warning;
        priorityText = 'عالية الأولوية';
        break;
      case 'low':
        priorityColor = AppTheme.textMuted;
        priorityText = 'منخفضة';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v == 'edit') _openForm(item: task);
                    if (v == 'cancel') _cancelTask(task);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل الخطة', style: TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    if (task.status != 'cancelled')
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 18, color: AppTheme.danger),
                            SizedBox(width: 8),
                            Text('إلغاء الخطة', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.danger)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (task.siteName != null && task.siteName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    task.siteName!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ],
              ),
            ],
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (task.progress / 100).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.progress >= 100 ? AppTheme.success : AppTheme.primaryTeal,
                      ),
                      minHeight: 6,
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
}