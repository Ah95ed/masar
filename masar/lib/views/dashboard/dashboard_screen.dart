import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/management_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/responsive_container.dart';

/// لوحة مؤشرات وتحكم المدير العام (Maxlond Management)
class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mgmtProvider = context.watch<ManagementProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('لوحة قيادة المدير العام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث المؤشرات',
            onPressed: () => mgmtProvider.fetchDashboard(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (mgmtProvider.dashboardState == LoadingState.loading &&
              mgmtProvider.dashboard.sitesCount == 0 &&
              mgmtProvider.dashboard.engineersCount == 0) {
            return const LoadingWidget(message: 'جاري تحميل مؤشرات الإدارة والتشغيل...');
          }

          if (mgmtProvider.dashboardState == LoadingState.error &&
              mgmtProvider.dashboard.sitesCount == 0) {
            return ErrorView(
              message: mgmtProvider.dashboardError ?? 'تعذر تحميل مؤشرات لوحة التحكم.',
              onRetry: () => mgmtProvider.fetchDashboard(),
            );
          }

          final data = mgmtProvider.dashboard;

          return RefreshIndicator(
            onRefresh: () => mgmtProvider.fetchDashboard(),
            color: const Color(0xFF0F172A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ترويسة الترحيب بالمدير العام
                    _buildAdminHero(user?.displayName ?? 'المدير العام'),
                    const SizedBox(height: 20),

                    // شبكة المؤشرات الرئيسية
                    _buildKpiHeader(),
                    const SizedBox(height: 12),
                    _buildKpiGrid(data),
                    const SizedBox(height: 24),

                    // ترتيب أفضل المهندسين أداءً لليوم
                    _buildTopEngineersCard(data.todayTopEngineers),
                    const SizedBox(height: 24),

                    // بطاقات الوصول السريع للمدير
                    _buildQuickActionShortcuts(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminHero(String adminName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 36,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً بك، $adminName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'المدير العام • صلاحية كاملة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'مؤشرات الأداء والموارد التشغيلية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Row(
          children: [
            Icon(Icons.fiber_manual_record, size: 10, color: Color(0xFF10B981)),
            SizedBox(width: 4),
            Text(
              'تحديث حي',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiGrid(DashboardModel data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'مواقع العمل النشطة',
                value: '${data.sitesCount}',
                subtitle: 'المشاريع قيد التنفيذ',
                icon: Icons.domain_rounded,
                color: const Color(0xFF0284C7),
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'المهندسون الميدانيون',
                value: '${data.engineersCount}',
                subtitle: 'الكوادر الهندسية',
                icon: Icons.engineering_rounded,
                color: const Color(0xFF0D9488),
                onTap: () => widget.onNavigateTab?.call(7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'أسطول الآليات',
                value: '${data.machineryCount}',
                subtitle: 'معدات ومضخات وحفارات',
                icon: Icons.precision_manufacturing_rounded,
                color: const Color(0xFF6366F1),
                onTap: () => widget.onNavigateTab?.call(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'تقارير بانتظار الاعتماد',
                value: '${data.pendingReportsCount}',
                subtitle: 'تتطلب مراجعة واعتماد',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: 'إجمالي قيمة المواد في المخزن',
          value: ArabicHelpers.formatCurrency(data.inventoryValue),
          subtitle: 'تقييم الأصناف المتوفرة بالمستودع',
          icon: Icons.warehouse_rounded,
          color: const Color(0xFF10B981),
          onTap: () => widget.onNavigateTab?.call(5),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
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
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopEngineersCard(List<TopEngineerModel> topEngineers) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.military_tech_rounded, color: Color(0xFFF59E0B), size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'متصدرو الأداء الهندسي لليوم (Today\'s Top Engineers)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'ترتيب المهندسين حسب نقاط التقييم ونشاط المهام المنجزة الميدانية',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Divider(height: 24),
            if (topEngineers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'لا توجد بيانات ترتيب للمهندسين اليوم حتى الآن',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topEngineers.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final eng = topEngineers[index];
                  final rank = index + 1;
                  Color rankColor = const Color(0xFF64748B);
                  if (rank == 1) rankColor = const Color(0xFFF59E0B);
                  if (rank == 2) rankColor = const Color(0xFF94A3B8);
                  if (rank == 3) rankColor = const Color(0xFFB45309);

                  return Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: rankColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eng.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'النشاطات: ${eng.activityCount} • المهام المكتملة: ${eng.completedTasks}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              '${eng.score.toStringAsFixed(1)} نقطة',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإجراءات الإدارية السريعة',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildShortcutButton(
                label: 'مراجعة التقارير',
                icon: Icons.rate_review_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                label: 'مواقع العمل',
                icon: Icons.apartment_rounded,
                color: const Color(0xFF0284C7),
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                label: 'خطط العمل',
                icon: Icons.assignment_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                label: 'المالية والقيود',
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF10B981),
                onTap: () => widget.onNavigateTab?.call(6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
