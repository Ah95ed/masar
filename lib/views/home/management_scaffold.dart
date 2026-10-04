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

/// الهيكل التنفيذي المتكامل لتطبيق المدير العام المطابق للوحة تحكم Just_admin
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
              Text('تسجيل الخروج'),
            ],
          ),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
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

    // الصفحات التنفيذية الثمانية
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

    // أسماء الأقسام المختصرة والمطابقة لـ Just_admin
    final List<String> pageTitles = [
      'لوحة التحكم',
      'المواقع',
      'خطط العمل',
      'التقارير',
      'الآليات',
      'المخزن',
      'الحسابات',
      'المستخدمون',
    ];

    final isWideScreen = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.ink,
        elevation: 0,
        leading: isWideScreen
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  tooltip: 'القائمة الرئيسية',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withOpacity(0.2),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'الإشعارات',
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
                      color: AppTheme.red,
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
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
              color: AppTheme.cyanPale,
              child: Row(
                children: [
                  const Icon(Icons.science_rounded, size: 18, color: AppTheme.cyan),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الوضع التجريبي نشط (محاكاة Just_admin بدون خادم)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.ink),
                    ),
                  ),
                  InkWell(
                    onTap: () => auth.exitDemoMode(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.ink,
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
      );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.cyanPale,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded, color: AppTheme.cyan),
          label: Text('لوحة التحكم'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on_rounded, color: AppTheme.cyan),
          label: Text('المواقع'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded, color: AppTheme.cyan),
          label: Text('خطط العمل'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_turned_in_outlined),
          selectedIcon: Icon(Icons.assignment_turned_in_rounded, color: AppTheme.cyan),
          label: Text('التقارير'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping_rounded, color: AppTheme.amber),
          label: Text('الآليات'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.green),
          label: Text('المخزن'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded, color: AppTheme.cyan),
          label: Text('الحسابات'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group_rounded, color: AppTheme.cyan),
          label: Text('المستخدمون'),
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
                color: AppTheme.ink,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
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
                    'لوحة الإدارة المركزية - Just Admin',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildDrawerTile(0, 'لوحة التحكم', Icons.grid_view_rounded),
            _buildDrawerTile(1, 'المواقع', Icons.location_on_rounded),
            _buildDrawerTile(2, 'خطط العمل', Icons.assignment_rounded),
            _buildDrawerTile(3, 'التقارير', Icons.assignment_turned_in_rounded),
            _buildDrawerTile(4, 'الآليات', Icons.local_shipping_rounded),
            _buildDrawerTile(5, 'المخزن', Icons.inventory_2_rounded),
            _buildDrawerTile(6, 'الحسابات', Icons.menu_book_rounded),
            _buildDrawerTile(7, 'المستخدمون', Icons.group_rounded),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: AppTheme.ink),
              title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
      leading: Icon(icon, color: isSelected ? AppTheme.cyan : AppTheme.muted),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.cyan : AppTheme.textPrimary,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.cyanPale,
      onTap: () {
        Navigator.pop(context);
        _onTabSelected(index);
      },
    );
  }
}
