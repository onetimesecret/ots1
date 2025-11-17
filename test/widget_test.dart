// This is a basic test file to demonstrate the testing setup.
// Additional tests should be added for each component.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onetimesecret_mobile/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OTSApp());

    // Verify that the home screen loads
    expect(find.text('One-Time Secret'), findsOneWidget);
  });

  testWidgets('Home screen has create and retrieve buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OTSApp());

    // Verify the main action buttons are present
    expect(find.text('Create Secret'), findsOneWidget);
    expect(find.text('Retrieve Secret'), findsOneWidget);
  });

  testWidgets('Navigation to create secret screen works',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OTSApp());

    // Tap the create secret button
    await tester.tap(find.text('Create Secret'));
    await tester.pumpAndSettle();

    // Verify we're on the create secret screen
    expect(find.text('Create Secret'), findsWidgets);
  });

  testWidgets('Navigation to retrieve secret screen works',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OTSApp());

    // Tap the retrieve secret button
    await tester.tap(find.text('Retrieve Secret'));
    await tester.pumpAndSettle();

    // Verify we're on the retrieve secret screen
    expect(find.text('Retrieve Secret'), findsWidgets);
  });
}
