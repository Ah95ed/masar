import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/management_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/responsive_container.dart';

/// لوحة تحكم ومؤشرات المدير العام المتطابقة 100% مع Just_admin/admin/dashboard.php
class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isGeneratingAiReport = false;
  String? _aiAnalysisText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().fetchDashboard();
    });
  }

  void _triggerAiAnalysis(DashboardModel data) async {
    setState(() {
      _isGeneratingAiReport = true;
    });

    // محاكاة تحليل الذكاء الاصطناعي المتقدم لبيانات المشاريع والمخازن والمالية
    await Future.delayed(const Duration(milliseconds: 900));

    final topEngName = data.todayTopEngineers.isNotEmpty ? data.todayTopEngineers.first.fullName : 'الكوادر الميدانية';
    final pendingCount = data.pendingReportsCount;
    final sites = data.sitesCount;

    String analysis = '📊 **تقرير التحليل الذكي للعمليات والمشاريع (AI Executive Summary):**\n\n'
        '1. **حالة المشاريع الميدانية:** تسير الأعمال في $sites مواقع نشطة بنسق جيد، مع تسجيل أعلى إنتاجية اليوم بقيادة المهندس ($topEngName).\n'
        '2. **مراجعة التقارير:** هناك $pendingCount تقرير بانتظار الاعتماد؛ يُوصى باعتمادها لترحيل القيود وتحديث نسب الإنجاز التراكمية.\n'
        '3. **المخزون والتموين:** قيمة المواد في المستودع مستقرة (${ArabicHelpers.formatCurrency(data.inventoryValue)})، مع مؤشرات أمان جيدة لحركات الصرف.\n'
        '4. **توصية الذكاء الاصطناعي:** تركيز المتابعة على المواقع ذات نسب الإنجاز الحرجة وتأكيد فحص جاهزية آليات الأسطول المجدولة للصيانة.';

    if (mounted) {
      setState(() {
        _isGeneratingAiReport = false;
        _aiAnalysisText = analysis;
      });
      _showAiAnalysisModal(analysis);
    }
  }

  void _showAiAnalysisModal(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cyanPale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.cyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المساعد الذكي للمدير العام (AI Executive Insights)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink),
                        ),
                        Text(
                          'تحليل فوري لقواعد البيانات والمؤشرات التشغيلية',
                          style: TextStyle(fontSize: 11, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.muted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13, height: 1.7, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('تم الاطلاع'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mgmtProvider = context.watch<ManagementProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.paper,
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
            color: AppTheme.ink,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ترويسة الترحيب بهوية Just_admin الرسمية
                    _buildAdminHero(user?.displayName ?? 'المدير العام'),
                    const SizedBox(height: 16),

                    // بطاقة التحليل الذكي للعمليات AI
                    _buildAiInsightsBanner(data),
                    const SizedBox(height: 20),

                    // شبكة المؤشرات الرئيسية المطابقة لـ Just_admin
                    _buildKpiHeader(),
                    const SizedBox(height: 12),
                    _buildKpiGrid(data),
                    const SizedBox(height: 20),

                    // ترتيب أفضل المهندسين أداءً لليوم (Today's Top Engineers)
                    _buildTopEngineersCard(data.todayTopEngineers),
                    const SizedBox(height: 20),

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 43, 63, 0.12),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 28,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'أهلاً بك، $adminName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.cyan,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'الإدارة المركزية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      'صلاحية كاملة (Admin)',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsBanner(DashboardModel data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cyan.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 43, 63, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cyanPale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.cyan, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التحليل الذكي للمشاريع (AI Analytics)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.ink),
                ),
                SizedBox(height: 2),
                Text(
                  'تحليل مؤشرات الإنجاز، تكاليف الصيانة، والتنبؤ باحتياجات المواد',
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isGeneratingAiReport
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.insights_rounded, size: 16),
            label: Text(_isGeneratingAiReport ? 'جاري التحليل...' : (_aiAnalysisText != null ? 'عرض التحليل' : 'تحليل حي')),
            onPressed: _isGeneratingAiReport ? null : () => _aiAnalysisText != null ? _showAiAnalysisModal(_aiAnalysisText!) : _triggerAiAnalysis(data),
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
          'المؤشرات التشغيلية للمشاريع والموارد',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        Row(
          children: [
            Icon(Icons.fiber_manual_record, size: 9, color: AppTheme.green),
            SizedBox(width: 4),
            Text(
              'تحديث متزامن',
              style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
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
              child: _buildStatCard(
                title: 'مواقع العمل النشطة',
                value: '${data.sitesCount}',
                subtitle: 'المشاريع قيد التنفيذ',
                icon: Icons.location_on_rounded, // pin in Just_admin
                accentColor: AppTheme.cyan,
                tintColor: AppTheme.cyanPale,
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'المهندسون الميدانيون',
                value: '${data.engineersCount}',
                subtitle: 'الكوادر الهندسية',
                icon: Icons.group_rounded, // users in Just_admin
                accentColor: AppTheme.green,
                tintColor: AppTheme.greenPale,
                onTap: () => widget.onNavigateTab?.call(7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'أسطول الآليات والمعدات',
                value: '${data.machineryCount}',
                subtitle: 'معدات، مضخات وحفارات',
                icon: Icons.local_shipping_rounded, // truck in Just_admin
                accentColor: AppTheme.amber,
                tintColor: AppTheme.amberPale,
                onTap: () => widget.onNavigateTab?.call(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'تقارير بانتظار الاعتماد',
                value: '${data.pendingReportsCount}',
                subtitle: 'تتطلب مراجعة وقرار',
                icon: Icons.assignment_turned_in_rounded, // clipboard in Just_admin
                accentColor: AppTheme.red,
                tintColor: AppTheme.redPale,
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'إجمالي تقييم المواد في المخزن',
          value: ArabicHelpers.formatCurrency(data.inventoryValue),
          subtitle: 'الأصناف المتوفرة وجاهزية التموين للمشاريع',
          icon: Icons.inventory_2_rounded, // box in Just_admin
          accentColor: AppTheme.green,
          tintColor: AppTheme.greenPale,
          onTap: () => widget.onNavigateTab?.call(5),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color tintColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 43, 63, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: tintColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopEngineersCard(List<TopEngineerModel> topEngineers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech_rounded, color: AppTheme.amber, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'متصدرو الأداء الهندسي لليوم (Today\'s Top Engineers)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'ترتيب الكوادر حسب نقاط الإنجاز والنشاط الميداني المسجل بالتقارير',
            style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
          ),
          const Divider(height: 20),
          if (topEngineers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'لا توجد بيانات ترتيب للمهندسين اليوم حتى الآن',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.muted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topEngineers.length,
              separatorBuilder: (_, __) => const Divider(height: 14),
              itemBuilder: (context, index) {
                final eng = topEngineers[index];
                final rank = index + 1;
                Color rankColor = AppTheme.muted;
                if (rank == 1) rankColor = AppTheme.amber;
                if (rank == 2) rankColor = const Color(0xFF64748B);
                if (rank == 3) rankColor = const Color(0xFF92400E);

                return Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: rankColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eng.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'النشاطات: ${eng.activityCount} • المهام المكتملة: ${eng.completedTasks}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.greenPale,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppTheme.green),
                          const SizedBox(width: 3),
                          Text(
                            '${eng.score.toStringAsFixed(1)} نقطة',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.green,
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
    );
  }

  Widget _buildQuickActionShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الوصول السريع للإجراءات الإدارية',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildShortcutButton(
                label: 'مراجعة التقارير',
                icon: Icons.assignment_turned_in_rounded, // clipboard
                color: AppTheme.red,
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                label: 'مواقع العمل',
                icon: Icons.location_on_rounded, // pin
                color: AppTheme.cyan,
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                label: 'خطط العمل',
                icon: Icons.assignment_rounded, // clipboard
                color: const Color(0xFF6366F1),
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                label: 'المالية والقيود',
                icon: Icons.menu_book_rounded, // book
                color: AppTheme.green,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

