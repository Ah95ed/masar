import 'package:flutter/material.dart';

import 'core/secure_storage.dart';
import 'services/session_manager.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorage.instance.init();
  await SessionManager.instance.restore();
  runApp(const MaxlondApp());
}
