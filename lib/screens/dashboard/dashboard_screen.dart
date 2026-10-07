import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/admin_api.dart';
import '../../services/session_manager.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';

class DashboardScreen extends StatefulWidget {
  final AdminApi api;
  final Function(int tabIndex)? onNavigateTab;
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.user;
    final fullName = user?['full_name']?.toString() ?? 'المدير العام';
    final dashProv = context.watch<DashboardProvider>();

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
      ),
      body: dashProv.isLoading && dashProv.data == null
          ? const LoadingState(message: 'جاري تحميل مؤشرات الأداء...')
          : dashProv.error != null && dashProv.data == null
              ? ErrorState(message: dashProv.error!, onRetry: () => dashProv.fetchDashboard())
              : RefreshIndicator(
                  onRefresh: () => dashProv.fetchDashboard(),
                  color: AppTheme.primaryTeal,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ترحيب بالمدير
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryDark, Color(0xFF1E3A5F)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryDark.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.primaryTeal.withOpacity(0.2),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AppTheme.primaryTeal,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مرحباً، $fullName',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'نظرة عامة على المشاريع والعمليات الميدانية',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // بطاقات الإحصائيات الرئيسية
                      const Text(
                        'المؤشرات العامة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsGrid(dashProv),

                      const SizedBox(height: 24),

                      // أفضل المهندسين أداءً
                      _buildTopEngineersSection(dashProv),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsGrid(DashboardProvider prov) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'المواقع النشطة',
          value: '${prov.activeSites} / ${prov.totalSites}',
          icon: Icons.location_city_rounded,
          accentColor: AppTheme.accentCyan,
          onTap: () => widget.onNavigateTab?.call(1),
        ),
        StatCard(
          title: 'تقارير بالانتظار',
          value: prov.pendingReports,
          icon: Icons.assignment_late_outlined,
          accentColor: AppTheme.warning,
          onTap: () => widget.onNavigateTab?.call(3),
        ),
        StatCard(
          title: 'المهام الجارية',
          value: prov.activeTasks,
          icon: Icons.task_alt_rounded,
          accentColor: AppTheme.success,
          onTap: () => widget.onNavigateTab?.call(2),
        ),
        StatCard(
          title: 'الآليات والمعدات',
          value: prov.totalMachinery,
          icon: Icons.precision_manufacturing_rounded,
          accentColor: AppTheme.primaryDark,
        ),
        StatCard(
          title: 'مواد دون الحد الأدنى',
          value: prov.lowStockItems,
          icon: Icons.inventory_2_outlined,
          accentColor: AppTheme.danger,
          onTap: () => widget.onNavigateTab?.call(4),
        ),
        StatCard(
          title: 'مجموع المواقع',
          value: prov.totalSites,
          icon: Icons.business_rounded,
          accentColor: AppTheme.primaryTeal,
          onTap: () => widget.onNavigateTab?.call(1),
        ),
      ],
    );
  }

  Widget _buildTopEngineersSection(DashboardProvider prov) {
    final list = prov.topEngineers;

    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أفضل المهندسين إنجازاً',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final eng = list[index] as Map<String, dynamic>;
              final name = eng['engineer_name'] ?? eng['full_name'] ?? 'مهندس';
              final count = eng['reports_count']?.toString() ?? '0';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count تقرير',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
