import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:medicare1/login_Screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login screen loads', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: login_Screen()));

    await tester.pump();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
