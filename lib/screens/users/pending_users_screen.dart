import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/constants.dart';

import '../../models/user.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/confirm_dialog.dart';

import '../../widgets/pill.dart';
import '../../widgets/state_view.dart';

class PendingUsersScreen extends StatefulWidget {
  final AdminApi api;

  const PendingUsersScreen({super.key, required this.api});

  @override
  State<PendingUsersScreen> createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      dynamic res;
      try {
        res = await widget.api.get('pending-users');
      } catch (_) {
        // Fallback: جلب المستخدمين وفلترة غير المفعلين
        res = await widget.api.get('users');
      }

      if (!mounted) return;
      final all = (res as List).map((e) => User.fromJson(Map<String, dynamic>.from(e))).toList();
      setState(() {
        _users = all.where((u) => u.isActive == 0 || !u.isApproved).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل طلبات التسجيل';
        _loading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    try {
      dynamic res;
      try {
        res = await widget.api.get('pending-users');
      } catch (_) {
        res = await widget.api.get('users');
      }
      if (!mounted) return;
      final all = (res as List).map((e) => User.fromJson(Map<String, dynamic>.from(e))).toList();
      setState(() {
        _users = all.where((u) => u.isActive == 0 || !u.isApproved).toList();
      });
    } catch (_) {}
  }

      Future<void> _approveUser(User user) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'اعتماد الحساب',
      message: 'هل أنت متأكد من رغبتك في اعتماد حساب "" وتفعيله؟',
      confirmText: 'اعتماد الحساب',
      isDestructive: false,
    );

    if (!confirmed || !mounted) return;
    setState(() => _actionLoading = true);

    bool succeeded = false;
    dynamic lastError;

    final fullUserBody = <String, dynamic>{
      'id': user.id,
      'user_id': user.id,
      'full_name': user.fullName.trim().isNotEmpty ? user.fullName.trim() : (user.username.isNotEmpty ? user.username : 'مهندس ميداني'),
      'username': user.username.trim().isNotEmpty ? user.username.trim() : 'eng_',
      'email': user.email.trim().isNotEmpty ? user.email.trim() : 'eng_@maxlond.com',
      'role': user.role.trim().isNotEmpty ? user.role.trim() : 'engineer',
      'phone': user.phone ?? '',
      'specialization': user.specialization ?? '',
      'is_active': 1,
      'status': 'active',
      'approval_status': 'approved',
    };

    // 1. المحاولة الأساسية: user-save بكامل البيانات المطلوبة للتحقق من الاسم واسم المستخدم والبريد والدور
    try {
      await widget.api.post('user-save', fullUserBody);
      succeeded = true;
    } catch (e) {
      lastError = e;
    }

    // 2. المحاولة الثانية: user-status
    if (!succeeded) {
      try {
        await widget.api.post('user-status', {
          'user_id': user.id,
          'id': user.id,
          'status': 'active',
          'is_active': 1,
          'approval_status': 'approved',
        });
        succeeded = true;
      } catch (e) {
        lastError = e;
      }
    }

    // 3. المحاولة الثالثة: user-approve
    if (!succeeded) {
      try {
        await widget.api.post('user-approve', {
          'user_id': user.id,
          'id': user.id,
          'status': 'active',
          'is_active': 1,
          'approval_status': 'approved',
        });
        succeeded = true;
      } catch (e) {
        lastError = e;
      }
    }

    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم اعتماد الحساب وتفعيله بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kGreen,
        ),
      );
      await _fetchPending();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اعتماد الحساب: $lastError', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
  }

  Future<void> _rejectUser(User user) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'رفض طلب التسجيل',
      message: 'هل أنت متأكد من رفض طلب حساب ""؟',
      confirmText: 'رفض الطلب',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;
    setState(() => _actionLoading = true);

    bool succeeded = false;
    dynamic lastError;

    final fullRejectBody = <String, dynamic>{
      'id': user.id,
      'user_id': user.id,
      'full_name': user.fullName.trim().isNotEmpty ? user.fullName.trim() : (user.username.isNotEmpty ? user.username : 'مهندس ميداني'),
      'username': user.username.trim().isNotEmpty ? user.username.trim() : 'eng_',
      'email': user.email.trim().isNotEmpty ? user.email.trim() : 'eng_@maxlond.com',
      'role': user.role.trim().isNotEmpty ? user.role.trim() : 'engineer',
      'phone': user.phone ?? '',
      'specialization': user.specialization ?? '',
      'is_active': 0,
      'status': 'rejected',
      'approval_status': 'rejected',
    };

    // 1. المحاولة الأساسية: user-save مع حالة rejected و is_active: 0
    try {
      await widget.api.post('user-save', fullRejectBody);
      succeeded = true;
    } catch (e) {
      lastError = e;
    }

    // 2. المحاولة الثانية: user-status
    if (!succeeded) {
      try {
        await widget.api.post('user-status', {
          'user_id': user.id,
          'id': user.id,
          'status': 'rejected',
          'is_active': 0,
          'approval_status': 'rejected',
        });
        succeeded = true;
      } catch (e) {
        lastError = e;
      }
    }

    // 3. المحاولة الثالثة: user-reject
    if (!succeeded) {
      try {
        await widget.api.post('user-reject', {
          'user_id': user.id,
          'id': user.id,
          'status': 'rejected',
          'is_active': 0,
          'approval_status': 'rejected',
        });
        succeeded = true;
      } catch (e) {
        lastError = e;
      }
    }

    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض طلب التسجيل', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
      await _fetchPending();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل رفض الطلب: $lastError', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: kRed,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return AutoRefreshWrapper(
      interval: const Duration(seconds: 30),
      onRefresh: _silentRefresh,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('طلبات التسجيل'),
              const SizedBox(width: 8),
              if (_users.isNotEmpty)
                Pill.warning(text: '${_users.length} بانتظار الاعتماد'),
            ],
          ),
        ),
        body: StateView(
          loading: _loading,
          error: _error,
          empty: _users.isEmpty,
          emptyMessage: 'لا توجد طلبات تسجيل معلقة حالياً',
          onRetry: _fetchPending,
          child: RefreshIndicator(
            onRefresh: _fetchPending,
            color: kCyan,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  elevation: 0,
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
                          children: [
                            CircleAvatar(
                              backgroundColor: kAmberPale,
                              child: const Icon(Icons.person_add_rounded, color: kAmber, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName.isNotEmpty ? user.fullName : user.username,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: kInk,
                                    ),
                                  ),
                                  Text(
                                    '${user.username} · ${user.email}',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Pill.warning(text: user.roleLabel),
                          ],
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: kMuted),
                              const SizedBox(width: 4),
                              Text(user.phone!, style: const TextStyle(fontSize: 12, color: kMuted)),
                              if (user.specialization != null && user.specialization!.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.work_outline, size: 14, color: kMuted),
                                const SizedBox(width: 4),
                                Text(user.specialization!, style: const TextStyle(fontSize: 12, color: kMuted)),
                              ],
                            ],
                          ),
                        ],
                        const Divider(height: 20, color: kLine),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _actionLoading ? null : () => _rejectUser(user),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kRed,
                                side: const BorderSide(color: kRed),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('رفض الطلب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _actionLoading ? null : () => _approveUser(user),
                              style: FilledButton.styleFrom(
                                backgroundColor: kGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('اعتماد الحساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}