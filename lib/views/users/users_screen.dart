import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_helpers.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

/// شاشة إدارة الكادر والمستخدمين للمدير العام (مهندسون، محاسبون)
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().fetchUsers();
    });
  }

  // ==================== حوار إنشاء أو تعديل مستخدم ====================
  void _showUserDialog([UserModel? user]) {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController(text: user?.username);
    final fullNameCtrl = TextEditingController(text: user?.fullName);
    final emailCtrl = TextEditingController(text: user?.email);
    final phoneCtrl = TextEditingController(text: user?.phone);
    final passwordCtrl = TextEditingController();
    String role = user?.role ?? 'engineer';
    bool obscurePassword = true;

    final isNew = user == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(isNew ? 'إضافة حساب كادر جديد' : 'تعديل بيانات المستخدم'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(ctx).size.height * 0.72,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(hintText: 'الدور الوظيفي والصلاحية *'),
                      items: const [
                        DropdownMenuItem(value: 'engineer', child: Text('مهندس موقع ميداني (Engineer)')),
                        DropdownMenuItem(value: 'accountant', child: Text('محاسب مالي (Accountant)')),
                        DropdownMenuItem(value: 'admin', child: Text('مدير عام (Admin)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => role = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(hintText: 'الاسم الثلاثي الكامل *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: usernameCtrl,
                      enabled: isNew, // اسم المستخدم لا يُعدل بعد الإنشاء
                      decoration: InputDecoration(
                        hintText: 'اسم المستخدم للولوج (Username) *',
                        helperText: isNew ? 'حروف إنجليزية وأرقام بدون مسافات' : null,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 10),
                    if (isNew) ...[
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور الأولية (10 أحرف على الأقل) *',
                          helperText: 'يجب أن لا تقل عن 10 أحرف وأرقام للأمان الإلزامي',
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 10) {
                            return 'كلمة المرور يجب أن لا تقل عن 10 خانات';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(6)),
                        child: const Row(
                          children: [
                            Icon(Icons.security_rounded, size: 16, color: Colors.blueGrey),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'لن يتم عرض كلمة المرور نهائياً بعد الإنشاء حفاظاً على الخصوصية.',
                                style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(hintText: 'البريد الإلكتروني (اختياري)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(hintText: 'رقم الهاتف (اختياري)'),
                    ),
                  ],
                ),
              ),
            ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payload = {
                    if (user != null) 'id': user.id,
                    'username': usernameCtrl.text.trim(),
                    'full_name': fullNameCtrl.text.trim(),
                    'role': role,
                    if (isNew) 'password': passwordCtrl.text,
                    if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
                    if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text.trim(),
                  };

                  final ok = await context.read<ManagementProvider>().saveUser(payload);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isNew ? 'تم إنشاء الحساب بنجاح.' : 'تم تحديث بيانات المستخدم بنجاح.'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
                child: Text(isNew ? 'إنشاء الحساب' : 'حفظ التعديل'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== تفعيل / تعطيل الحساب مع حظر تعطيل المدير الحالي ====================
  void _toggleUserStatus(UserModel user) {
    final currentAdminUsername = context.read<AuthProvider>().currentUser?.username;
    final isCurrentAdmin = (user.id == 1) || (user.username == currentAdminUsername);

    if (isCurrentAdmin) {
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.shield_rounded, color: AppTheme.dangerColor),
                SizedBox(width: 8),
                Text('إجراء محظور أمنياً'),
              ],
            ),
            content: const Text('غير مسموح إطلاقاً بتعطيل حساب المدير العام المسجل حالياً في المنظومة.'),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
            ],
          ),
        ),
      );
      return;
    }

    final newStatus = user.isActive ? 'inactive' : 'active';
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(user.isActive ? 'تعطيل حساب المستخدم' : 'إعادة تفعيل الحساب'),
          content: Text(
            user.isActive
                ? 'هل أنت متأكد من تعطيل حساب "${user.displayName}"؟ لن يتمكن من تسجيل الدخول للتطبيقات الميدانية.'
                : 'هل تريد إعادة تفعيل حساب "${user.displayName}" والسماح له بالدخول؟',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: user.isActive ? AppTheme.dangerColor : const Color(0xFF10B981)),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<ManagementProvider>().setUserStatus(user.id, newStatus);
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(user.isActive ? 'تم تعطيل الحساب.' : 'تم تفعيل الحساب بنجاح.'),
                      backgroundColor: user.isActive ? AppTheme.dangerColor : AppTheme.successColor,
                    ),
                  );
                }
              },
              child: Text(user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('إدارة الكادر والمستخدمين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () => prov.fetchUsers(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (prov.usersState == LoadingState.loading && prov.users.isEmpty) {
            return const LoadingWidget(message: 'جاري تحميل قائمة الكادر...');
          }

          if (prov.usersState == LoadingState.error && prov.users.isEmpty) {
            return ErrorView(message: prov.usersError ?? 'تعذر تحميل المستخدمين', onRetry: () => prov.fetchUsers());
          }

          if (prov.users.isEmpty) {
            return EmptyView(
              title: 'لا يوجد مستخدمون',
              message: 'أضف المهندسين والمحاسبين لتمكينهم من تسجيل الدخول في تطبيقاتهم.',
              icon: Icons.people_outline_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () => prov.fetchUsers(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = prov.users[index];
                final currentAdminUsername = context.read<AuthProvider>().currentUser?.username;
                final isCurrentAdmin = (user.id == 1) || (user.username == currentAdminUsername);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: user.isManager
                              ? const Color(0xFF0F172A).withValues(alpha: 0.1)
                              : user.isEngineer
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.1)
                                  : const Color(0xFF10B981).withValues(alpha: 0.1),
                          child: Icon(
                            user.isManager
                                ? Icons.admin_panel_settings_rounded
                                : user.isEngineer
                                    ? Icons.engineering_rounded
                                    : Icons.account_balance_wallet_rounded,
                            color: user.isManager
                                ? const Color(0xFF0F172A)
                                : user.isEngineer
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                  ),
                                  if (isCurrentAdmin) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('أنت', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${user.username}  •  ${ArabicHelpers.translateRole(user.role)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              if (user.phone != null) ...[
                                const SizedBox(height: 2),
                                Text(user.phone!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: user.isActive ? 'active' : 'inactive'),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'تعديل البيانات',
                                  onPressed: () => _showUserDialog(user),
                                ),
                                IconButton(
                                  icon: Icon(
                                    user.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                    size: 28,
                                    color: user.isActive ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                  tooltip: user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                                  onPressed: () => _toggleUserStatus(user),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_users_screen',
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('إضافة مستخدم'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
    );
  }
}
