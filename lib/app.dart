import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'services/admin_api.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/dashboard_provider.dart';
import 'providers/sites_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/warehouse_provider.dart';
import 'providers/users_provider.dart';
import 'providers/notifications_provider.dart';

class MaxlondApp extends StatefulWidget {
  const MaxlondApp({super.key});

  @override
  State<MaxlondApp> createState() => _MaxlondAppState();
}

class _MaxlondAppState extends State<MaxlondApp> {
  late final AdminApi _api;

  @override
  void initState() {
    super.initState();
    _api = AdminApi();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => SitesProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => TasksProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => ReportsProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => WarehouseProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => UsersProvider(api: _api)),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(api: _api)),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: SplashScreen(api: _api),
      ),
    );
  }
}
