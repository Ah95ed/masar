import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:masar/core/network/api_client.dart';
import 'package:masar/main.dart';
import 'package:masar/providers/auth_provider.dart';
import 'package:masar/services/auth_service.dart';
import 'spacepoint_test.dart';

void main() {
  testWidgets('SpacePointApp launches and renders AuthGate smoke test', (WidgetTester tester) async {
    final mockStorage = MockStorageService();
    final mockClient = MockHttpClient((request) {
      return http.Response(
        jsonEncode({'success': false, 'error': {'code': 'UNAUTHORIZED', 'message': 'No session'}}),
        401,
      );
    });

    final apiClient = ApiClient(
      httpClient: mockClient,
      storageService: mockStorage,
    );

    final authService = AuthService(
      apiClient: apiClient,
      storageService: mockStorage,
    );

    final authProvider = AuthProvider(
      authService: authService,
      storageService: mockStorage,
    );

    await tester.pumpWidget(
      SpacePointApp(
        authProvider: authProvider,
      ),
    );

    await tester.pump();

    expect(find.byType(SpacePointApp), findsOneWidget);
    expect(find.byType(AuthGate), findsOneWidget);
  });
}
