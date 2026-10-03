import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/management_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../financial/financial_screen.dart';
import '../fleet_repairs/fleet_repairs_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reports_review/reports_review_screen.dart';
import '../sites/sites_screen.dart';
import '../users/users_screen.dart';
import '../warehouse/warehouse_screen.dart';
import '../work_plans/work_plans_screen.dart';

/// الهيكل التنفيذي المتكامل لتطبيق المدير العام Maxlond Management
class ManagementScaffold extends StatefulWidget {
  const ManagementScaffold({super.key});

  @override
  State<ManagementScaffold> createState() => _ManagementScaffoldState();
}

class _ManagementScaffoldState extends State<ManagementScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().fetchNotifications();
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.dangerColor),
              SizedBox(width: 8),
              Text('تسجيل خروج المدير'),
            ],
          ),
          content: const Text('هل أنت متأكد من إنهاء جلسة الإدارة وتسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthProvider>().logout();
              },
              child: const Text('تأكيد الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mgmt = context.watch<ManagementProvider>();
    final unreadCount = mgmt.unreadNotificationsCount;

    // الصفحات الثمانية التنفيذية للمدير العام فقط
    final List<Widget> pages = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const SitesScreen(),
      const WorkPlansScreen(),
      const ReportsReviewScreen(),
      const FleetRepairsScreen(),
      const WarehouseScreen(),
      const FinancialScreen(),
      const UsersScreen(),
    ];

    // عناوين الصفحات
    final List<String> pageTitles = [
      'لوحة المؤشرات',
      'مواقع العمل الإنشائية',
      'خطط العمل التنفيذية',
      'مراجعة التقارير',
      'الآليات والصيانة',
      'المستودع والمخزن',
      'المالية والحسابات',
      'إدارة المستخدمين',
    ];

    final isWideScreen = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                Text(
                  pageTitles[_currentIndex],
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // شارة إشعار التنبيهات
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'الإشعارات والتنبيهات',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // زر الخروج
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      drawer: isWideScreen ? null : _buildDrawer(context),
      body: Column(
        children: [
          if (auth.isDemoMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.science_rounded, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الوضع التجريبي نشط (محاكاة المدير العام بدون خادم)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  InkWell(
                    onTap: () => auth.exitDemoMode(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'إنهاء التجربة',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                if (isWideScreen) _buildNavigationRail(),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex > 3 ? 4 : _currentIndex,
              onDestinationSelected: (idx) {
                if (idx == 4) {
                  // فتح درج الأقسام الإضافية
                  Scaffold.of(context).openDrawer();
                } else {
                  _onTabSelected(idx);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'المؤشرات',
                ),
                NavigationDestination(
                  icon: Icon(Icons.apartment_outlined),
                  selectedIcon: Icon(Icons.apartment_rounded),
                  label: 'المواقع',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment_rounded),
                  label: 'الخطط',
                ),
                NavigationDestination(
                  icon: Icon(Icons.rate_review_outlined),
                  selectedIcon: Icon(Icons.rate_review_rounded),
                  label: 'التقارير',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'المزيد',
                ),
              ],
            ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('المؤشرات'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment_rounded),
          label: Text('مواقع العمل'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: Text('خطط العمل'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.rate_review_outlined),
          selectedIcon: Icon(Icons.rate_review_rounded),
          label: Text('مراجعة التقارير'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.precision_manufacturing_outlined),
          selectedIcon: Icon(Icons.precision_manufacturing_rounded),
          label: Text('الآليات والصيانة'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.warehouse_outlined),
          selectedIcon: Icon(Icons.warehouse_rounded),
          label: Text('المستودع والمخزن'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_outlined),
          selectedIcon: Icon(Icons.account_balance_rounded),
          label: Text('المالية والحسابات'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('إدارة المستخدمين'),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.displayName ?? 'المدير العام',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'لوحة الإدارة المركزية - Maxlond',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildDrawerTile(0, 'لوحة المؤشرات العامة', Icons.dashboard_rounded),
            _buildDrawerTile(1, 'مواقع العمل الإنشائية والمشاريع', Icons.apartment_rounded),
            _buildDrawerTile(2, 'خطط العمل التنفيذية والمهام', Icons.assignment_rounded),
            _buildDrawerTile(3, 'مراجعة واعتماد التقارير الميدانية', Icons.rate_review_rounded),
            _buildDrawerTile(4, 'أسطول الآليات وسجلات الصيانة', Icons.precision_manufacturing_rounded),
            _buildDrawerTile(5, 'المستودع والمخزون وحركات الصرف', Icons.warehouse_rounded),
            _buildDrawerTile(6, 'الإدارة المالية ودليل الحسابات والقيود', Icons.account_balance_rounded),
            _buildDrawerTile(7, 'إدارة الكادر والمستخدمين والصلاحيات', Icons.people_rounded),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
              title: const Text('الإشعارات والتنبيهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.dangerColor),
              title: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF0284C7).withValues(alpha: 0.08),
      onTap: () {
        Navigator.pop(context);
        _onTabSelected(index);
      },
    );
  }
}
