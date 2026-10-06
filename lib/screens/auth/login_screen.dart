import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/admin_api.dart';
import '../admin_scaffold.dart';

class LoginScreen extends StatefulWidget {
  final AdminApi api;

  const LoginScreen({super.key, required this.api});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = await widget.api.login(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      if (user['role'] != 'admin') {
        throw const ApiException(
          403,
          'unauthorized_role',
          'عذراً، هذا الحساب ليس بصلاحية مدير عام (admin)',
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminScaffold(api: widget.api)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر الاتصال بالخادم، يرجى المحاولة لاحقاً',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDark,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryDark.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              size: 36,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'بوابة المدير العام (Admin Portal)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _usernameCtrl,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                            hintText: 'username',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المستخدم' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'يرجى إدخال كلمة المرور' : null,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loading ? null : _handleLogin,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'الإصدار ',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}