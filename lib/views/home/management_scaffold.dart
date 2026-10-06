import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/management_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../engineer_updates/engineer_updates_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reports_review/reports_review_screen.dart';
import '../sites/sites_screen.dart';
import '../users/users_screen.dart';
import '../warehouse/warehouse_screen.dart';
import '../work_plans/work_plans_screen.dart';

/// الهيكل التنفيذي الرئيسي لتطبيق Maxlond Management المطابق للأقسام المعتمدة
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
              ),
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

    // الأقسام المعتمدة في النظام المطابقة للصورة المرفقة
    final List<Widget> pages = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const SitesScreen(),
      const WorkPlansScreen(),
      const ReportsReviewScreen(),
      const WarehouseScreen(),
      const EngineerUpdatesScreen(),
      const UsersScreen(),
      const NotificationsScreen(),
    ];

    final List<String> pageTitles = [
      'لوحة التحكم',
      'المواقع',
      'خطط العمل',
      'التقارير اليومية',
      'توقيع حركات المخزن',
      'تحديثات المهندسين',
      'المستخدمون',
      'الإشعارات',
    ];

    final isWideScreen = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F273D),
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
                color: const Color(0xFF00A2A5).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                size: 20,
                color: Color(0xFF00A2A5),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    pageTitles[_currentIndex],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF88A6BD),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                tooltip: 'الإشعارات',
                onPressed: () => _onTabSelected(7),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.dangerColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
              color: const Color(0xFFFEF3C7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الوضع التجريبي نشط (محاكاة بدون خادم)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                  child: IndexedStack(index: _currentIndex, children: pages),
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
      backgroundColor: const Color(0xFF0F273D),
      indicatorColor: const Color(0xFF0D3B52),
      unselectedLabelTextStyle: const TextStyle(color: Color(0xFFBACEDC), fontSize: 11),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
      unselectedIconTheme: const IconThemeData(color: Color(0xFFBACEDC)),
      selectedIconTheme: const IconThemeData(color: Color(0xFF00A2A5)),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: Text('لوحة التحكم'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.location_on_outlined),
          label: Text('المواقع'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          label: Text('خطط العمل'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: Text('التقارير اليومية'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.check_rounded),
          label: Text('توقيع المخزن'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          label: Text('تحديثات المهندسين'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          label: Text('المستخدمون'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications_none_rounded),
          label: Text('الإشعارات'),
        ),
      ],
    );
  }

  /// القائمة الجانبية (Drawer) بتطابق كامل وتام مع التصميم المرفق في الصورة
  Widget _buildDrawer(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = user?.displayName ?? 'Ahmed';
    final initialLetter = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'A';

    return Drawer(
      backgroundColor: const Color(0xFF0F273D),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ترويسة Maxlond
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A2A5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ML',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maxlond',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'إدارة المشاريع المدنية',
                            style: TextStyle(
                              color: Color(0xFF88A6BD),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF1E3A52), height: 1),
              const SizedBox(height: 12),

              // 2. بطاقة المستخدم
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF1E3A5F),
                      child: Text(
                        initialLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'مدير النظام',
                            style: TextStyle(
                              color: Color(0xFF88A6BD),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. عنوان الفئة
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'القائمة الرئيسية',
                  style: TextStyle(
                    color: Color(0xFF6B8BA4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // 4. عناصر القائمة الثمانية
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    _buildDrawerItem(0, 'لوحة التحكم', Icons.grid_view_rounded),
                    _buildDrawerItem(1, 'المواقع', Icons.location_on_outlined),
                    _buildDrawerItem(2, 'خطط العمل', Icons.assignment_outlined),
                    _buildDrawerItem(3, 'التقارير اليومية', Icons.bar_chart_rounded),
                    _buildDrawerItem(4, 'توقيع حركات المخزن', Icons.check_rounded),
                    _buildDrawerItem(5, 'تحديثات المهندسين', Icons.assignment_outlined),
                    _buildDrawerItem(6, 'المستخدمون', Icons.people_outline_rounded),
                    _buildDrawerItem(7, 'الإشعارات', Icons.notifications_none_rounded),
                  ],
                ),
              ),

              // 5. زر تسجيل الخروج
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132F45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFBACEDC),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              color: Color(0xFFBACEDC),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. تذييل الحالة والإصدار
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'متصل',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'الإصدار 2.0.0',
                      style: TextStyle(
                        color: Color(0xFF6B8BA4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.pop(context);
          _onTabSelected(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D3B52) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: const Color(0xFF00A2A5), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFFBACEDC),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFBACEDC),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}