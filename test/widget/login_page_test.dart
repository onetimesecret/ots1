import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onetimesecret/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.text('Onetimesecret'), findsWidgets);
      expect(find.text('Privacy-first secret sharing'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should show validation errors when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Tap login button without filling fields
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your API key'), findsOneWidget);
    });

    testWidgets('should show help dialog when help button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.tap(find.text('How to get an API key?'));
      await tester.pumpAndSettle();

      expect(find.text('Getting an API Key'), findsOneWidget);
      expect(find.text('Visit onetimesecret.com'), findsOneWidget);
    });
  });
}
