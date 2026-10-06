import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
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
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

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
      final res = await widget.api.get('dashboard');
      if (!mounted) return;
      setState(() {
        _data = res is Map<String, dynamic> ? res : Map<String, dynamic>.from(res as Map);
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
        _error = 'حدث خطأ أثناء تحميل لوحة التحكم';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.user;
    final fullName = user?['full_name']?.toString() ?? 'المدير العام';

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar حسب التعليمات الصارمة
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل مؤشرات الأداء...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
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
                      _buildStatsGrid(),

                      const SizedBox(height: 24),

                      // أفضل المهندسين أداءً
                      _buildTopEngineersSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _data?['stats'] as Map<String, dynamic>? ?? {};

    final totalSites = stats['total_sites']?.toString() ?? '0';
    final activeSites = stats['active_sites']?.toString() ?? '0';
    final pendingReports = stats['pending_reports']?.toString() ?? '0';
    final activeTasks = stats['active_tasks']?.toString() ?? '0';
    final totalMachinery = stats['total_machinery']?.toString() ?? '0';
    final lowStockItems = stats['low_stock_items']?.toString() ?? '0';

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
          value: '$activeSites / $totalSites',
          icon: Icons.location_city_rounded,
          accentColor: AppTheme.accentCyan,
          onTap: () => widget.onNavigateTab?.call(1),
        ),
        StatCard(
          title: 'تقارير بالانتظار',
          value: pendingReports,
          icon: Icons.assignment_late_outlined,
          accentColor: AppTheme.warning,
          onTap: () => widget.onNavigateTab?.call(2),
        ),
        StatCard(
          title: 'المهام الجارية',
          value: activeTasks,
          icon: Icons.task_alt_rounded,
          accentColor: AppTheme.success,
          onTap: () => widget.onNavigateTab?.call(1),
        ),
        StatCard(
          title: 'الآليات والمعدات',
          value: totalMachinery,
          icon: Icons.precision_manufacturing_rounded,
          accentColor: AppTheme.primaryDark,
        ),
        StatCard(
          title: 'مواد دون الحد الأدنى',
          value: lowStockItems,
          icon: Icons.inventory_2_outlined,
          accentColor: AppTheme.danger,
          onTap: () => widget.onNavigateTab?.call(3),
        ),
        StatCard(
          title: 'مجموع المواقع',
          value: totalSites,
          icon: Icons.business_rounded,
          accentColor: AppTheme.primaryTeal,
          onTap: () => widget.onNavigateTab?.call(1),
        ),
      ],
    );
  }

  Widget _buildTopEngineersSection() {
    final list = _data?['top_engineers'] as List? ?? [];

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final eng = list[index] as Map<String, dynamic>;
              final name = eng['engineer_name']?.toString() ?? 'مهندس';
              final count = eng['reports_count']?.toString() ?? '0';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0] : 'م',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'عدد التقارير المعتمدة: $count',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.star_rounded,
                  color: AppTheme.warning,
                  size: 22,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}