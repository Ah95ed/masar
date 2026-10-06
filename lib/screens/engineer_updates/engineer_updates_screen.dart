import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
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
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('tasks');
      if (!mounted) return;
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['tasks'] ?? res['data'] ?? res['items'] ?? [];
      }
      setState(() {
        _tasks = rawList
            .whereType<Map>()
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
            .toList();
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
        _error = 'حدث خطأ أثناء تحميل تحديثات المهندسين';
        _loading = false;
      });
    }
  }

  List<Task> get _filteredTasks {
    if (_selectedStatusFilter == 'all') return _tasks;
    return _tasks.where((t) => t.status.toLowerCase() == _selectedStatusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = _tasks;
    final inProgressCount = allTasks.where((t) => t.status.toLowerCase() == 'in_progress').length;
    final doneCount = allTasks.where((t) => t.status.toLowerCase() == 'done' || t.status.toLowerCase() == 'completed').length;
    final reviewCount = allTasks.where((t) => t.status.toLowerCase() == 'review').length;
    final avgProgress = allTasks.isEmpty
        ? 0
        : (allTasks.fold<int>(0, (acc, t) => acc + t.progress) / allTasks.length).round();

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('تحديثات المهندسين الميدانية'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل سجل تحديثات المهندسين...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppTheme.primaryTeal,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // بطاقات المؤشرات السريعة
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'قيد التنفيذ',
                              value: '$inProgressCount',
                              icon: Icons.pending_actions_rounded,
                              accent: AppTheme.primaryTeal,
                              bg: AppTheme.primaryTeal.withOpacity(0.12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'متوسط الإنجاز',
                              value: '$avgProgress%',
                              icon: Icons.trending_up_rounded,
                              accent: AppTheme.success,
                              bg: AppTheme.success.withOpacity(0.12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'المكتملة',
                              value: '$doneCount',
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
                            _buildFilterChip('all', 'كافة التحديثات (${allTasks.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('in_progress', 'قيد التنفيذ ($inProgressCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('review', 'قيد المراجعة ($reviewCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('done', 'المكتملة ($doneCount)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_filteredTasks.isEmpty)
                        const EmptyState(
                          title: 'لا توجد تحديثات',
                          message: 'لم يتم العثور على تحديثات مهندسين مطابقة للفلتر المحدد.',
                          icon: Icons.rate_review_outlined,
                        )
                      else
                        ..._filteredTasks.map((t) => _buildTaskUpdateCard(t)),
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedStatusFilter = key);
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
