import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masar/app.dart';
import 'package:masar/core/secure_storage.dart';
import 'package:masar/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MaxlondApp launches and renders splash screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.instance.init();
    await SessionManager.instance.restore();

    await tester.pumpWidget(const MaxlondApp());
    expect(find.byType(MaxlondApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
  });
}