import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/notifications_provider.dart';
import '../services/admin_api.dart';
import '../services/session_manager.dart';
import '../widgets/confirm_dialog.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'sites/sites_screen.dart';
import 'tasks/tasks_screen.dart';
import 'reports/reports_screen.dart';
import 'warehouse/warehouse_moves_screen.dart';
import 'engineer_updates/engineer_updates_screen.dart';
import 'users/users_screen.dart';
import 'notifications/notifications_screen.dart';

class AdminScaffold extends StatefulWidget {
  final AdminApi api;

  const AdminScaffold({super.key, required this.api});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });
  }

  void _onSelectDrawerItem(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟',
      confirmText: 'خروج',
      isDestructive: true,
    );

    if (!confirmed) return;

    await widget.api.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
      (route) => false,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = SessionManager.instance.user;
    final fullName = user?['full_name']?.toString() ?? 'Ahmed';
    final initialLetter = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'A';
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;

    return Drawer(
      backgroundColor: const Color(0xFF0F273D),
      width: 300,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ترويسة Maxlond
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
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
                            AppConstants.appName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'إدارة المشاريع المدنية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
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
              const SizedBox(height: 10),

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
                          fontFamily: 'Cairo',
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
                            fullName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'مدير النظام',
                            style: TextStyle(
                              fontFamily: 'Cairo',
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

              const SizedBox(height: 14),

              // 3. عنوان الفئة
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'القائمة الرئيسية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFF6B8BA4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // 4. عناصر القائمة الثمانية المطابقة للصورة المرفقة
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    _buildDrawerItem(0, 'لوحة التحكم', Icons.grid_view_rounded),
                    _buildDrawerItem(1, 'المواقع', Icons.location_on_outlined),
                    _buildDrawerItem(2, 'خطط العمل', Icons.assignment_outlined),
                    _buildDrawerItem(3, 'التقارير اليومية', Icons.insert_chart_outlined_rounded),
                    _buildDrawerItem(4, 'توقيع حركات المخزن', Icons.check_circle_outline_rounded),
                    _buildDrawerItem(5, 'تحديثات المهندسين', Icons.rate_review_outlined),
                    _buildDrawerItem(6, 'المستخدمون', Icons.people_outline_rounded),
                    _buildDrawerItem(7, 'الإشعارات', Icons.notifications_none_rounded, unreadCount),
                  ],
                ),
              ),

              // 5. زر تسجيل الخروج والتذييل
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16324D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFBACEDC), size: 18),
                        SizedBox(width: 10),
                        Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // التذييل: متصل ● الإصدار 2.0.0
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A2A5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'متصل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFF00A2A5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'الإصدار 2.0.0',
                      style: TextStyle(
                        fontFamily: 'Cairo',
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
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon, [int badge = 0]) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _onSelectDrawerItem(index);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                  color: isSelected ? const Color(0xFF00D1D5) : const Color(0xFF88A6BD),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFBACEDC),
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawer = _buildDrawer(context);

    return IndexedStack(
      index: _currentIndex,
      children: [
        DashboardScreen(
          api: widget.api,
          onNavigateTab: _onSelectDrawerItem,
          drawer: drawer,
        ),
        SitesScreen(
          api: widget.api,
          drawer: drawer,
        ),
        TasksScreen(
          api: widget.api,
          drawer: drawer,
        ),
        ReportsScreen(
          api: widget.api,
          drawer: drawer,
        ),
        WarehouseMovesScreen(
          api: widget.api,
          drawer: drawer,
        ),
        EngineerUpdatesScreen(
          api: widget.api,
          drawer: drawer,
        ),
        UsersScreen(
          api: widget.api,
          drawer: drawer,
        ),
        NotificationsScreen(
          api: widget.api,
          drawer: drawer,
        ),
      ],
    );
  }
}
