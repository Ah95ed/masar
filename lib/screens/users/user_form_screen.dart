import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../services/admin_api.dart';

class UserFormScreen extends StatefulWidget {
  final AdminApi api;
  final User? item;

  const UserFormScreen({super.key, required this.api, this.item});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _specializationCtrl;
  late final TextEditingController _passwordCtrl;

  late String _role;
  bool _saving = false;
  bool _obscurePassword = true;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _fullNameCtrl = TextEditingController(text: it?.fullName ?? '');
    _usernameCtrl = TextEditingController(text: it?.username ?? '');
    _emailCtrl = TextEditingController(text: it?.email ?? '');
    _phoneCtrl = TextEditingController(text: it?.phone ?? '');
    _specializationCtrl = TextEditingController(text: it?.specialization ?? '');
    _passwordCtrl = TextEditingController();

    _role = it?.role ?? 'engineer';
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _specializationCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final body = <String, dynamic>{
        'full_name': _fullNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _role,
        'phone': _phoneCtrl.text.trim(),
        'specialization': _specializationCtrl.text.trim(),
      };

      if (!_isEdit) {
        body['password'] = _passwordCtrl.text;
      } else {
        body['id'] = widget.item!.id;
        if (_passwordCtrl.text.isNotEmpty) {
          body['password'] = _passwordCtrl.text;
        }
      }

      await widget.api.post('user-save', body);

      if (!mounted) return;
      // ✅ القاعدة الذهبية: الخروج وإرجاع true لجلب البيانات الحقيقية من السيرفر
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ غير متوقع أثناء حفظ المستخدم', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل المستخدم' : 'إضافة مستخدم جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم (Username) *',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'اسم المستخدم مطلوب';
                if (!RegExp(r'^[A-Za-z0-9_.-]{3,80}$').hasMatch(v)) {
                  return 'يجب أن يكون من 3 إلى 80 حرفاً إنجليزياً أو أرقام';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
                if (!v.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'الدور والوظيفة *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'engineer', child: Text('مهندس موقع')),
                DropdownMenuItem(value: 'accountant', child: Text('محاسب مالي')),
                DropdownMenuItem(value: 'warehouse', child: Text('مسؤول المستودع')),
                DropdownMenuItem(value: 'fleet_manager', child: Text('مسؤول الآليات والأسطول')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'engineer'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: _isEdit ? 'كلمة المرور (اتركها فارغة للإبقاء على الحالية)' : 'كلمة المرور * (10 أحرف كحد أدنى)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (!_isEdit && (v == null || v.length < 10)) {
                  return 'كلمة المرور يجب ألا تقل عن 10 أحرف وأرقام';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specializationCtrl,
              decoration: const InputDecoration(
                labelText: 'التخصص المهني (مثل: هندسة مدنية، ميكانيك)',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isEdit ? 'حفظ التعديلات' : 'إنشاء الحساب',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}