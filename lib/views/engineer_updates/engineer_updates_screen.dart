import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/work_plan_model.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

/// شاشة تحديثات المهندسين (سجل تغييرات التقدم والحالة وملاحظات التنفيذ الميداني)
class EngineerUpdatesScreen extends StatefulWidget {
  const EngineerUpdatesScreen({super.key});

  @override
  State<EngineerUpdatesScreen> createState() => _EngineerUpdatesScreenState();
}

class _EngineerUpdatesScreenState extends State<EngineerUpdatesScreen> {
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ManagementProvider>();
      p.fetchWorkPlans();
      p.fetchDashboard();
      p.fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ManagementProvider>();

    if (prov.workPlansState == LoadingState.loading && prov.workPlans.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل سجل تحديثات المهندسين...');
    }

    final allPlans = prov.workPlans;
    final filteredPlans = _selectedStatusFilter == 'all'
        ? allPlans
        : allPlans.where((p) => p.status.toLowerCase() == _selectedStatusFilter).toList();

    final inProgressCount = allPlans.where((p) => p.status.toLowerCase() == 'in_progress').length;
    final doneCount = allPlans.where((p) => p.status.toLowerCase() == 'done').length;
    final reviewCount = allPlans.where((p) => p.status.toLowerCase() == 'review').length;
    final avgProgress = allPlans.isEmpty
        ? 0
        : (allPlans.fold<int>(0, (acc, p) => acc + p.progress) / allPlans.length).round();

    return RefreshIndicator(
      color: AppTheme.ink,
      onRefresh: () async {
        await prov.fetchWorkPlans();
        await prov.fetchDashboard();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقات الإحصاءات السريعة
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'قيد التنفيذ',
                  value: '$inProgressCount',
                  icon: Icons.pending_actions_rounded,
                  accent: AppTheme.cyan,
                  bg: AppTheme.cyanPale,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  label: 'متوسط الإنجاز',
                  value: '$avgProgress%',
                  icon: Icons.trending_up_rounded,
                  accent: AppTheme.green,
                  bg: AppTheme.greenPale,
                ),
              ),
              const SizedBox(width: 10),
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
                _buildFilterChip('all', 'كافة التحديثات (${allPlans.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'قيد التنفيذ ($inProgressCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('review', 'قيد المراجعة ($reviewCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('done', 'المكتملة ($doneCount)'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // قائمة التحديثات والمهام
          if (filteredPlans.isEmpty)
            EmptyView(
              title: 'لا توجد تحديثات مسجلة',
              message: 'لم يتم العثور على تحديثات مهندسين مطابقة للفلتر المحدد.',
              action: ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث البيانات'),
                onPressed: () => prov.fetchWorkPlans(),
              ),
            )
          else
            ...filteredPlans.map((plan) => _buildUpdateCard(plan)),
        ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent),
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
      selectedColor: AppTheme.cyanPale,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.cyan : AppTheme.ink,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.cyan : AppTheme.line,
      ),
    );
  }

  Widget _buildUpdateCard(WorkPlanModel plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة: المهندس والموقع
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.cyanPale,
                child: const Icon(Icons.engineering_rounded, color: AppTheme.cyan, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.assignedToName ?? (plan.isBroadcast ? 'تعميم على كافة المهندسين' : 'مهندس ميداني'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            plan.siteName ?? 'موقع غير محدد',
                            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(status: plan.status),
            ],
          ),
          const Divider(height: 16),

          // عنوان المهمة وملاحظات التنفيذ
          Text(
            plan.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink),
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.description!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
          ],
          const SizedBox(height: 12),

          // شريط التقدم ونسبة الإنجاز
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('نسبة تقدم الإنجاز:', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
              Text(
                '${plan.progress}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.cyan),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (plan.progress / 100.0).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                plan.progress >= 100
                    ? AppTheme.green
                    : (plan.progress >= 50 ? AppTheme.cyan : AppTheme.amber),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // تذييل البطاقة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text(
                    plan.createdAt ?? '',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'الأولوية: ${ArabicHelpers.translatePriority(plan.priority)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}