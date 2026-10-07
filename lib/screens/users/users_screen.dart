import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../providers/users_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'user_form_screen.dart';

class UsersScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const UsersScreen({super.key, required this.api, this.drawer});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchUsers();
    });
  }

  Future<void> _openForm({User? item}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(api: widget.api, item: item),
      ),
    );

    if (saved == true && mounted) {
      await context.read<UsersProvider>().fetchUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? 'تم إنشاء الحساب بنجاح' : 'تم تحديث الحساب بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _toggleStatus(User user) async {
    final willDeactivate = user.isActive == 1;
    final confirmed = await ConfirmDialog.show(
      context,
      title: willDeactivate ? 'تعطيل الحساب' : 'تفعيل الحساب',
      message: willDeactivate
          ? 'هل أنت متأكد من تعطيل حساب "${user.fullName}"؟'
          : 'هل ترغب في إعادة تفعيل حساب "${user.fullName}"؟',
      confirmText: willDeactivate ? 'تعطيل' : 'تفعيل',
      isDestructive: willDeactivate,
    );

    if (!confirmed || !mounted) return;

    final success = await context.read<UsersProvider>().toggleUserStatus(user);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willDeactivate ? 'تم تعطيل الحساب' : 'تم تفعيل الحساب بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersProv = context.watch<UsersProvider>();
    final users = usersProv.filteredUsers;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('إدارة المستخدمين وفريق العمل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'إضافة مستخدم',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: usersProv.isLoading && usersProv.users.isEmpty
          ? const LoadingState(message: 'جاري تحميل المستخدمين...')
          : usersProv.error != null && usersProv.users.isEmpty
              ? ErrorState(message: usersProv.error!, onRetry: () => usersProv.fetchUsers())
              : RefreshIndicator(
                  onRefresh: () => usersProv.fetchUsers(),
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(usersProv),
                      Expanded(
                        child: users.isEmpty
                            ? const EmptyState(
                                title: 'لا يوجد مستخدمون',
                                message: 'لم يتم العثور على مستخدمين يطابقون خيارات البحث',
                                icon: Icons.people_outline,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return _buildUserTile(user);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFiltersHeader(UsersProvider prov) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => prov.setSearch(v),
            decoration: const InputDecoration(
              hintText: 'بحث بالاسم، اسم المستخدم، البريد...',
              prefixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleChip('all', 'الكل (${prov.users.length})', prov),
                _buildRoleChip('engineer', 'المهندسون', prov),
                _buildRoleChip('accountant', 'المحاسبون', prov),
                _buildRoleChip('admin', 'المدراء', prov),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, String label, UsersProvider prov) {
    final isSelected = prov.filterRole == role;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => prov.setRoleFilter(role),
        selectedColor: AppTheme.primaryDark,
        backgroundColor: Colors.grey.shade100,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  Widget _buildUserTile(User user) {
    final isActive = user.isActive == 1;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withOpacity(0.12),
          child: Icon(
            _getRoleIcon(user.role),
            color: _getRoleColor(user.role),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.success : AppTheme.danger).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'نشط' : 'معطل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.success : AppTheme.danger,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '@${user.username} • ${user.email}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getRoleName(user.role),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getRoleColor(user.role),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textMuted),
          onSelected: (val) {
            if (val == 'edit') _openForm(item: user);
            if (val == 'toggle') _toggleStatus(user);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('تعديل الحساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.block_outlined : Icons.check_circle_outline,
                    size: 18,
                    color: isActive ? AppTheme.danger : AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: isActive ? AppTheme.danger : AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير عام';
      case 'engineer':
        return 'مهندس موقع';
      case 'accountant':
        return 'محاسب مالي';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.primaryDark;
      case 'engineer':
        return AppTheme.primaryTeal;
      case 'accountant':
        return const Color(0xFF6366F1);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'engineer':
        return Icons.engineering_outlined;
      case 'accountant':
        return Icons.account_balance_outlined;
      default:
        return Icons.person_outline;
    }
  }
}
