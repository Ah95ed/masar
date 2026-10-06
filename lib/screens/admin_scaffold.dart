import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/admin_api.dart';
import '../services/session_manager.dart';
import '../widgets/confirm_dialog.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'sites/sites_screen.dart';
import 'tasks/tasks_screen.dart';
import 'reports/reports_screen.dart';
import 'warehouse/warehouse_moves_screen.dart';
import 'warehouse/warehouse_items_screen.dart';
import 'users/users_screen.dart';
import 'machinery/machinery_screen.dart';
import 'accounting/accounts_screen.dart';
import 'accounting/journal_screen.dart';
import 'accounting/financial_screen.dart';
import 'notifications/notifications_screen.dart';

class AdminScaffold extends StatefulWidget {
  final AdminApi api;

  const AdminScaffold({super.key, required this.api});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _currentBottomIndex = 0;

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

  void _navigateToTab(int index) {
    setState(() => _currentBottomIndex = index);
  }

  Widget _buildBody() {
    switch (_currentBottomIndex) {
      case 0:
        return DashboardScreen(api: widget.api, onNavigateTab: _navigateToTab);
      case 1:
        return _buildProjectsTabs();
      case 2:
        return ReportsScreen(api: widget.api);
      case 3:
        return _buildWarehouseTabs();
      case 4:
        return NotificationsScreen(api: widget.api);
      default:
        return DashboardScreen(api: widget.api, onNavigateTab: _navigateToTab);
    }
  }

  Widget _buildProjectsTabs() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المشاريع'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryTeal,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'المواقع الإنشائية'),
              Tab(text: 'خطط وتوجيهات العمل'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SitesScreen(api: widget.api),
            TasksScreen(api: widget.api),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseTabs() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المخزن والمستودع'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryTeal,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'حركات الصرف والتوريد'),
              Tab(text: 'المواد والأرصدة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            WarehouseMovesScreen(api: widget.api),
            WarehouseItemsScreen(api: widget.api),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.user;
    final fullName = user?['full_name'] ?? 'المدير العام';
    final email = user?['email'] ?? 'admin@vehiclegate.ghusun.net';

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryDark, Color(0xFF1E3A5F)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.primaryTeal,
                child: Text(
                  fullName.isNotEmpty ? fullName[0] : 'A',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              accountName: Text(
                fullName,
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                email,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded, color: AppTheme.primaryDark),
                    title: const Text('لوحة التحكم الرئيسية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomIndex = 0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.business_rounded, color: AppTheme.primaryDark),
                    title: const Text('المواقع والمشاريع', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomIndex = 1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_rounded, color: AppTheme.primaryDark),
                    title: const Text('خطط العمل والتوجيهات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomIndex = 1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_rounded, color: AppTheme.primaryDark),
                    title: const Text('التقارير اليومية الميدانية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomIndex = 2);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.warehouse_rounded, color: AppTheme.primaryDark),
                    title: const Text('المخزن والمستودع', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomIndex = 3);
                    },
                  ),
                  const Divider(color: AppTheme.border),
                  ListTile(
                    leading: const Icon(Icons.people_rounded, color: AppTheme.primaryDark),
                    title: const Text('إدارة المستخدمين وفريق العمل', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UsersScreen(api: widget.api)),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryDark),
                    title: const Text('أسطول الآليات والمعدات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MachineryScreen(api: widget.api)),
                      );
                    },
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryDark),
                    title: const Text('المحاسبة والمالية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    childrenPadding: const EdgeInsets.only(right: 24),
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.format_list_bulleted, size: 18),
                        title: const Text('دليل الحسابات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AccountsScreen(api: widget.api)),
                          );
                        },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.receipt_long, size: 18),
                        title: const Text('قيود اليومية', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => JournalScreen(api: widget.api)),
                          );
                        },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.bar_chart, size: 18),
                        title: const Text('ميزان المراجعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FinancialScreen(api: widget.api)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.danger, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentBottomIndex,
        onDestinationSelected: (idx) => setState(() => _currentBottomIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business_rounded),
            label: 'المشاريع',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'التقارير',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined),
            selectedIcon: Icon(Icons.warehouse_rounded),
            label: 'المخزن',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'الإشعارات',
          ),
        ],
      ),
    );
  }
}