import 'package:flutter/material.dart';

import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/create_secret/create_secret_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/reveal_secret/reveal_secret_page.dart';
import '../presentation/pages/secret_detail/secret_detail_page.dart';
import '../presentation/pages/splash/splash_page.dart';

/// App router for navigation
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String createSecret = '/create-secret';
  static const String revealSecret = '/reveal-secret';
  static const String secretDetail = '/secret-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );

      case createSecret:
        return MaterialPageRoute(
          builder: (_) => const CreateSecretPage(),
          settings: settings,
        );

      case revealSecret:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RevealSecretPage(
            secretKey: args?['secretKey'],
          ),
          settings: settings,
        );

      case secretDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => SecretDetailPage(
            secretKey: args['secretKey'],
            metadataKey: args['metadataKey'],
          ),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
