import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../../providers/users_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';
import 'pending_users_screen.dart';
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
            item == null ? 'تم إنشاء الحساب بنجاح' : 'تم تحديث بيانات الحساب بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: kGreen,
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
          backgroundColor: kGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersProv = context.watch<UsersProvider>();
    final users = usersProv.filteredUsers;
    final isWide = MediaQuery.of(context).size.width >= 850;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 60),
      onRefresh: () => usersProv.fetchUsers(),
      child: Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              tooltip: 'إضافة حساب',
              onPressed: () => _openForm(),
            ),
          ],
        ),
        body: StateView(
          loading: usersProv.isLoading && usersProv.users.isEmpty,
          error: usersProv.error,
          empty: false,
          onRetry: () => usersProv.fetchUsers(),
          child: RefreshIndicator(
            onRefresh: () => usersProv.fetchUsers(),
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderBar(),
                const SizedBox(height: 12),

                _buildFilterChips(usersProv),
                const SizedBox(height: 16),

                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('لا يوجد مستخدمون يطابقون معايير البحث', style: TextStyle(fontFamily: 'Cairo', color: kMuted)),
                    ),
                  )
                else if (isWide)
                  _buildUsersTable(users)
                else
                  _buildUsersCards(users),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'users_fab',
          onPressed: () => _openForm(),
          backgroundColor: kInk,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حسابات النظام والصلاحيات',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
              ),
              Text(
                'إدارة حسابات المهندسين والمحاسبين واعتماد طلبات التسجيل',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PendingUsersScreen(api: widget.api)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAmber,
                  side: const BorderSide(color: kAmber),
                ),
                icon: const Icon(Icons.pending_actions_rounded, size: 16),
                label: const Text('طلبات التسجيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openForm(),
                style: FilledButton.styleFrom(backgroundColor: kInk),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('إضافة حساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(UsersProvider prov) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildRoleChip('all', 'الكل (${prov.users.length})', prov),
          const SizedBox(width: 8),
          _buildRoleChip('engineer', 'المهندسون', prov),
          const SizedBox(width: 8),
          _buildRoleChip('accountant', 'المحاسبون', prov),
          const SizedBox(width: 8),
          _buildRoleChip('warehouse', 'أمناء المخازن', prov),
          const SizedBox(width: 8),
          _buildRoleChip('admin', 'الإدارة', prov),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, String label, UsersProvider prov) {
    final isSelected = prov.filterRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => prov.setRoleFilter(role),
      selectedColor: kInk,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : kInk,
      ),
      side: BorderSide(color: isSelected ? kInk : kLine),
    );
  }

  Widget _buildUsersTable(List<User> users) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kLine),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(kPaper),
          columns: const [
            DataColumn(label: Text('المستخدم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الدور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('التواصل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('آخر دخول', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
          ],
          rows: users.map((u) {
            final isAdmin = u.role == 'admin';
            final isActive = u.isActive == 1;

            return DataRow(
              cells: [
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName.isNotEmpty ? u.fullName : u.username, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    Text('${u.username} · ${u.email}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted)),
                  ],
                )),
                DataCell(Text(u.roleLabel, style: const TextStyle(fontFamily: 'Cairo'))),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.phone ?? '-', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    if (u.specialization != null)
                      Text(u.specialization!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: kMuted)),
                  ],
                )),
                DataCell(_buildStatusPill(u)),
                DataCell(const Text('مسجل نشط', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kMuted))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdmin)
                      const Pill.info(text: 'محمي')
                    else ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: kCyan),
                        tooltip: 'تعديل',
                        onPressed: () => _openForm(item: u),
                      ),
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.block_rounded : Icons.check_circle_outline,
                          size: 18,
                          color: isActive ? kRed : kGreen,
                        ),
                        tooltip: isActive ? 'تعطيل' : 'تفعيل',
                        onPressed: () => _toggleStatus(u),
                      ),
                    ],
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUsersCards(List<User> users) {
    return Column(
      children: users.map((u) {
        final isAdmin = u.role == 'admin';
        final isActive = u.isActive == 1;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: kLine),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      u.fullName.isNotEmpty ? u.fullName : u.username,
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
                    ),
                    _buildStatusPill(u),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${u.roleLabel} · ${u.username} · ${u.email}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
                ),
                if (u.phone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: kMuted),
                      const SizedBox(width: 4),
                      Text(u.phone!, style: const TextStyle(fontSize: 11, color: kMuted)),
                      if (u.specialization != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.work_outline, size: 13, color: kMuted),
                        const SizedBox(width: 4),
                        Text(u.specialization!, style: const TextStyle(fontSize: 11, color: kMuted)),
                      ],
                    ],
                  ),
                ],
                const Divider(height: 18, color: kLine),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAdmin)
                      const Pill.info(text: 'حساب المدير العام محمي')
                    else ...[
                      TextButton.icon(
                        onPressed: () => _openForm(item: u),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: kCyan),
                        label: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kCyan)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _toggleStatus(u),
                        icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline, size: 16, color: isActive ? kRed : kGreen),
                        label: Text(
                          isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isActive ? kRed : kGreen),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusPill(User u) {
    if (!u.isApproved) {
      return const Pill.warning(text: 'بانتظار الاعتماد');
    }
    if (u.isActive == 1) {
      return const Pill.success(text: 'معتمد ومفعل');
    }
    return const Pill.warning(text: 'معتمد ومعطل');
  }
}