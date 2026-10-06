import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/admin_api.dart';
import '../../services/session_manager.dart';
import '../admin_scaffold.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final AdminApi api;

  const SplashScreen({super.key, required this.api});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final hasSession = await widget.api.restoreSession();
    if (!mounted) return;

    final session = SessionManager.instance;
    if (hasSession && session.isAuthenticated && session.role == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminScaffold(api: widget.api)),
      );
    } else {
      if (session.isAuthenticated && session.role != 'admin') {
        await widget.api.logout();
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.4), width: 2),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 48,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              AppConstants.appSubtitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}