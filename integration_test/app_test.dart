import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onetimesecret_flutter/main.dart' as app;

/// Integration tests for OneTimeSecret Flutter app
///
/// These tests verify end-to-end functionality of the application
/// including navigation, API integration, and critical user flows.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch and Navigation', () {
    testWidgets('App launches and shows splash screen',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify splash screen or login page appears
      expect(
        find.text('OneTimeSecret'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Navigation to create secret page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip login if needed
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      // Find and tap create secret button/card
      final createButton = find.text('Create Secret');
      expect(createButton, findsAtLeastNWidgets(1));

      await tester.tap(createButton.first);
      await tester.pumpAndSettle();

      // Verify we're on create secret page
      expect(find.text('Secret'), findsWidgets);
    });

    testWidgets('Navigation to reveal secret page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip login
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      // Find and tap view secret button/card
      final viewButton = find.text('View Secret');
      expect(viewButton, findsAtLeastNWidgets(1));

      await tester.tap(viewButton.first);
      await tester.pumpAndSettle();

      // Verify we're on reveal secret page
      expect(find.text('Secret Key'), findsWidgets);
    });
  });

  group('Create Secret Flow', () {
    testWidgets('Can enter secret text and configure options',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip login and navigate to create secret
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Create Secret').first);
      await tester.pumpAndSettle();

      // Enter secret text
      final secretField = find.byType(TextFormField).first;
      await tester.enterText(secretField, 'This is a test secret message');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('This is a test secret message'), findsOneWidget);

      // Try to interact with TTL options
      final oneHourChip = find.text('1 hour');
      if (oneHourChip.evaluate().isNotEmpty) {
        await tester.tap(oneHourChip);
        await tester.pumpAndSettle();
      }

      // Verify passphrase toggle
      final passphraseSwitch = find.byType(SwitchListTile);
      if (passphraseSwitch.evaluate().isNotEmpty) {
        await tester.tap(passphraseSwitch.first);
        await tester.pumpAndSettle();

        // Should show passphrase field
        expect(find.text('Passphrase'), findsWidgets);
      }
    });

    testWidgets('Form validation works for empty secret',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to create secret
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Create Secret').first);
      await tester.pumpAndSettle();

      // Try to submit without entering secret
      final createButton = find.widgetWithText(ElevatedButton, 'Create Secret');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a secret'), findsOneWidget);
    });
  });

  group('Reveal Secret Flow', () {
    testWidgets('Can enter secret key', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reveal secret
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('View Secret').first);
      await tester.pumpAndSettle();

      // Enter secret key
      final keyField = find.byType(TextFormField).first;
      await tester.enterText(keyField, 'test-secret-key-12345');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('test-secret-key-12345'), findsOneWidget);
    });

    testWidgets('Form validation works for empty secret key',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reveal secret
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('View Secret').first);
      await tester.pumpAndSettle();

      // Try to submit without entering key
      final revealButton =
          find.widgetWithText(ElevatedButton, 'Reveal Secret');
      await tester.tap(revealButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a secret key'), findsOneWidget);
    });

    testWidgets('Can toggle passphrase requirement',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reveal secret
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('View Secret').first);
      await tester.pumpAndSettle();

      // Toggle passphrase switch
      final passphraseSwitch = find.byType(SwitchListTile);
      await tester.tap(passphraseSwitch.first);
      await tester.pumpAndSettle();

      // Should show passphrase field
      expect(find.text('Passphrase'), findsAtLeastNWidgets(1));

      // Enter passphrase
      final passphraseField = find.widgetWithText(TextFormField, 'Passphrase');
      await tester.enterText(passphraseField, 'test-passphrase');
      await tester.pumpAndSettle();
    });
  });

  group('Login Flow', () {
    testWidgets('Can navigate to login and enter credentials',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check if we're on login page
      final usernameField = find.byType(TextFormField).first;
      final apiKeyField = find.byType(TextFormField).last;

      // Enter credentials
      await tester.enterText(usernameField, 'testuser');
      await tester.pumpAndSettle();

      await tester.enterText(apiKeyField, 'test-api-key-12345');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('test-api-key-12345'), findsOneWidget);
    });

    testWidgets('Form validation works for empty credentials',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap login button without entering credentials
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.text('Please enter your username'), findsOneWidget);
        expect(find.text('Please enter your API key'), findsOneWidget);
      }
    });

    testWidgets('Can skip login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();

        // Should navigate to home page
        expect(find.text('Create Secret'), findsWidgets);
        expect(find.text('View Secret'), findsWidgets);
      }
    });
  });

  group('UI Responsiveness', () {
    testWidgets('App handles back button navigation',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip login
      final skipButton = find.text('Continue without login');
      if (skipButton.evaluate().isNotEmpty) {
        await tester.tap(skipButton);
        await tester.pumpAndSettle();
      }

      // Navigate to create secret
      await tester.tap(find.text('Create Secret').first);
      await tester.pumpAndSettle();

      // Press back button
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Should be back on home page
        expect(find.text('Create Secret'), findsWidgets);
      }
    });

    testWidgets('App renders correctly on different screen sizes',
        (WidgetTester tester) async {
      // Test with phone size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;

      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);

      // Test with tablet size
      tester.view.physicalSize = const Size(1536, 2048);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);

      // Reset to default size
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
