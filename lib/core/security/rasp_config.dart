import 'dart:io';
import 'package:freerasp/freerasp.dart';

/// Runtime Application Self-Protection (RASP) configuration
class RaspConfig {
  RaspConfig._();

  static TalsecConfig getConfig() {
    if (Platform.isAndroid) {
      return _getAndroidConfig();
    } else if (Platform.isIOS) {
      return _getIOSConfig();
    }
    throw UnsupportedError('Platform not supported');
  }

  static TalsecConfig _getAndroidConfig() {
    return TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.onetimesecret.app',
        signingCertHashes: [
          // Add your production signing certificate hash
          'AKoRuyLMM91E7lX/Zqp3u4jMmd0A7hH/Iqozu0TMVd0=',
        ],
        supportedAlternativeStores: [
          'com.sec.android.app.samsungapps',
        ],
      ),
      watcherMail: 'security@onetimesecret.com',
      isProd: true,
    );
  }

  static TalsecConfig _getIOSConfig() {
    return TalsecConfig(
      iosConfig: IOSConfig(
        bundleIds: 'com.onetimesecret.app',
        teamId: 'YOUR_TEAM_ID',
      ),
      watcherMail: 'security@onetimesecret.com',
      isProd: true,
    );
  }
}
