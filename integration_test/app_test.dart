import 'package:firebase_ai/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and reaches the login screen', (tester) async {
    app.main();

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
