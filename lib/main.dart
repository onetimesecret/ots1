import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freerasp/freerasp.dart';

import 'config/dependency_injection.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'core/constants/app_constants.dart';
import 'core/security/rasp_config.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/secret/secret_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock device orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependency injection
  await configureDependencies();

  // Initialize RASP (Runtime Application Self-Protection)
  await initializeRASP();

  runApp(const OneTimeSecretApp());
}

Future<void> initializeRASP() async {
  final config = RaspConfig.getConfig();

  final callback = ThreatCallback(
    onAppIntegrity: () => _handleSecurityThreat('App Integrity'),
    onObfuscationIssues: () => _handleSecurityThreat('Obfuscation'),
    onDebug: () => _handleSecurityThreat('Debug Mode'),
    onDeviceBinding: () => _handleSecurityThreat('Device Binding'),
    onDeviceID: () => _handleSecurityThreat('Device ID'),
    onHooks: () => _handleSecurityThreat('Hooks Detected'),
    onPasscode: () => _handleSecurityThreat('No Passcode'),
    onPrivilegedAccess: () => _handleSecurityThreat('Root/Jailbreak'),
    onSecureHardwareNotAvailable: () =>
        _handleSecurityThreat('Secure Hardware'),
    onSimulator: () => _handleSecurityThreat('Simulator'),
    onUnofficialStore: () => _handleSecurityThreat('Unofficial Store'),
  );

  try {
    await Talsec.start(config, callback);
  } catch (e) {
    debugPrint('RASP initialization failed: $e');
  }
}

void _handleSecurityThreat(String threat) {
  debugPrint('Security threat detected: $threat');
  // In production, you might want to:
  // - Log the event
  // - Show a warning to the user
  // - Restrict functionality
  // - Exit the app
}

class OneTimeSecretApp extends StatelessWidget {
  const OneTimeSecretApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<SecretBloc>(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
