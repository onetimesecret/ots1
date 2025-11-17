import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/dependency_injection.dart';
import 'core/security/security_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize security features
  await SecurityInitializer.initialize();

  // Setup dependency injection
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: OnetimesecretApp(),
    ),
  );
}
