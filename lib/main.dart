import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/management_provider.dart';
import 'services/auth_service.dart';
import 'services/management_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/management_scaffold.dart';
import 'views/widgets/loading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SecureStorageService();

  late final ApiClient apiClient;
  late final AuthProvider authProvider;

  apiClient = ApiClient(
    storageService: storageService,
    onSessionExpired: () {
      authProvider.handleSessionExpired();
    },
  );

  final authService = AuthService(
    apiClient: apiClient,
    storageService: storageService,
  );

  final managementService = ManagementService(apiClient: apiClient);

  authProvider = AuthProvider(
    authService: authService,
    storageService: storageService,
  );

  final managementProvider = ManagementProvider(service: managementService);

  runApp(
    SpacePointApp(
      authProvider: authProvider,
      managementProvider: managementProvider,
    ),
  );
}

/// التطبيق الرئيسي - Maxlond Management (إدارة مسار)
class SpacePointApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final ManagementProvider? managementProvider;

  const SpacePointApp({super.key, this.authProvider, this.managementProvider});

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorageService();
    late final ApiClient client;
    late final AuthProvider defaultAuth;

    client = ApiClient(
      storageService: storage,
      onSessionExpired: () => defaultAuth.handleSessionExpired(),
    );
    defaultAuth = AuthProvider(
      authService: AuthService(apiClient: client, storageService: storage),
      storageService: storage,
    );
    final defaultMgmt = ManagementProvider(
      service: ManagementService(apiClient: client),
    );

    final appContent = MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // تفعيل اللغة العربية والاتجاه RTL في كافة الشاشات
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider ?? defaultAuth,
        ),
        ChangeNotifierProvider<ManagementProvider>.value(
          value: managementProvider ?? defaultMgmt,
        ),
      ],
      child: appContent,
    );
  }
}

/// بوابة توجيه المدير العام وفق حالة المصادقة والصلاحية
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        return const Scaffold(
          body: LoadingWidget(message: 'جاري التحقق من جلسة المدير العام...'),
        );
      case AuthStatus.authenticated:
        return const ManagementScaffold();
      case AuthStatus.accessDenied:
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gpp_bad_rounded,
                      size: 56,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تم رفض الوصول (غير مصرح)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    auth.errorMessage ?? 'هذا التطبيق مقصور حصراً على حساب المدير العام (Admin). يرجى استخدام تطبيق المهندسين أو المحاسبين.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('العودة لتسجيل الدخول كمدير'),
                    onPressed: () {
                      auth.logout();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
