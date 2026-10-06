import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'services/admin_api.dart';
import 'screens/splash/splash_screen.dart';

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
    return MaterialApp(
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
    );
  }
}
