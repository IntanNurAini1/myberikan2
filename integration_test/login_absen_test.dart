import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myberikan/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login HR dan Absen Berhasil', (WidgetTester tester) async {
    app.main();

    await tester.pump(); 

    
    final usernameFinder = find.byKey(const Key('usernameField'));

    while (usernameFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.enterText(find.byKey(const Key('usernameField')), 'intan');

    await tester.enterText(find.byKey(const Key('passwordField')), 'Intan12@');

    await tester.tap(find.byKey(const Key('loginButton')));

    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.byKey(const Key('dashboardHR')), findsOneWidget);

    await tester.tap(find.byKey(const Key('absenButton')));

    await tester.pumpAndSettle();

    expect(find.textContaining('Absensi berhasil'), findsOneWidget);
  });
}
