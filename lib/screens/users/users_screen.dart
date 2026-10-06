import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
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
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  String _filterRole = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ القاعدة الذهبية: جلب البيانات دائماً من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('users');
      if (!mounted) return;
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        if (res['users'] is List) {
          rawList = res['users'] as List;
        } else if (res['data'] is List) {
          rawList = res['data'] as List;
        } else if (res['items'] is List) {
          rawList = res['items'] as List;
        }
      }
      setState(() {
        _users = rawList
            .whereType<Map>()
            .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
            .toList();
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
        _error = 'حدث خطأ أثناء تحميل المستخدمين';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({User? item}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(api: widget.api, item: item),
      ),
    );

    // ✅ إذا عاد النموذج بـ true نعيد الجلب من السيرفر فوراً
    if (saved == true) {
      await _load();
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

    if (!confirmed) return;

    try {
      await widget.api.post('user-status', {
        'user_id': user.id,
        'is_active': willDeactivate ? 0 : 1,
      });

      if (!mounted) return;
      // ✅ إعادة التحميل التلقائي فوراً من السيرفر
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willDeactivate ? 'تم تعطيل الحساب' : 'تم تفعيل الحساب بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  List<User> get _filteredUsers {
    return _users.where((u) {
      final matchesRole = _filterRole == 'all' || u.role.trim().toLowerCase() == _filterRole.trim().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('إدارة المستخدمين وفريق العمل'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'إضافة مستخدم',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل المستخدمين...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: Column(
                    children: [
                      _buildFiltersHeader(),
                      Expanded(
                        child: _filteredUsers.isEmpty
                            ? const EmptyState(
                                title: 'لا يوجد مستخدمون',
                                message: 'لم يتم العثور على مستخدمين يطابقون خيارات البحث',
                                icon: Icons.people_outline,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
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

  Widget _buildFiltersHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم، اسم المستخدم، البريد...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleChip('all', 'الكل (${_users.length})'),
                _buildRoleChip('engineer', 'المهندسون'),
                _buildRoleChip('accountant', 'المحاسبون'),
                _buildRoleChip('warehouse', 'المخزن'),
                _buildRoleChip('fleet_manager', 'الآليات'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, String label) {
    final isSelected = _filterRole == role;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
        selected: isSelected,
        selectedColor: AppTheme.primaryDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _filterRole = role),
      ),
    );
  }

  Widget _buildUserTile(User user) {
    final isActive = user.isActive == 1;

    String roleArabic = user.role;
    switch (user.role) {
      case 'admin':
        roleArabic = 'مدير عام';
        break;
      case 'engineer':
        roleArabic = 'مهندس موقع';
        break;
      case 'accountant':
        roleArabic = 'محاسب مالي';
        break;
      case 'warehouse':
        roleArabic = 'أمين مخزن';
        break;
      case 'fleet_manager':
        roleArabic = 'مسؤول آليات';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isActive ? AppTheme.primaryTeal.withOpacity(0.15) : AppTheme.border,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0] : '؟',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.primaryDark : AppTheme.textMuted,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
        subtitle: Text(
          '${user.username}  ·  $roleArabic',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.successLight : AppTheme.dangerLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'نشط' : 'موقوف',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.success : AppTheme.danger,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'edit') _openForm(item: user);
                if (v == 'toggle') _toggleStatus(user);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('تعديل الحساب', style: TextStyle(fontFamily: 'Cairo')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.block_rounded : Icons.check_circle_outline,
                        size: 18,
                        color: isActive ? AppTheme.danger : AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isActive ? AppTheme.danger : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}