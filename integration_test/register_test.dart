import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myberikan/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Register berhasil', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // isi form register
    await tester.enterText(
      find.byKey(const Key('nipField')),
      '103022330033',
    );

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'test@gmail.com',
    );

    await tester.enterText(
      find.byKey(const Key('usernameField')),
      'intan',
    );

    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'Admin@123',
    );

    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'Admin@123',
    );

    // klik daftar
    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // cek snackbar sukses
    expect(
      find.textContaining('Registrasi berhasil'),
      findsOneWidget,
    );
  });
}