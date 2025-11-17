# Build Guide - Onetimesecret Flutter App

This guide provides step-by-step instructions for building the Onetimesecret mobile application for iOS and Android.

## Prerequisites

### Required Software

- **Flutter SDK**: 3.38 or higher
- **Dart SDK**: 3.10 or higher
- **Android Studio** or **IntelliJ IDEA** (for Android builds)
- **Xcode** 15+ (for iOS builds, macOS only)
- **CocoaPods** (for iOS dependencies)

### Install Flutter

```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

Ensure `flutter doctor` shows no critical issues for your target platform.

## Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/onetimesecret/ots1.git
cd ots1
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Code Generation (if needed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Android Build

### Development Build

```bash
# Connect an Android device or start an emulator
flutter devices

# Run in debug mode
flutter run
```

### Release Build (APK)

```bash
# Build release APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# The APK will be located at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Release Build (App Bundle)

For Google Play Store distribution:

```bash
# Build release App Bundle
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

# The bundle will be located at:
# build/app/outputs/bundle/release/app-release.aab
```

### Signing Configuration

For production releases, you need to sign your app:

1. **Create a keystore**:

```bash
keytool -genkey -v -keystore ~/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onetimesecret
```

2. **Create `android/key.properties`**:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=onetimesecret
storeFile=<path-to-keystore>
```

3. **Update `android/app/build.gradle`** to use the signing config (uncomment the signing configuration section).

### ProGuard Configuration

The app is configured with ProGuard rules for code obfuscation. Rules are defined in `android/app/proguard-rules.pro`.

## iOS Build

### Development Build

```bash
# Open iOS simulator
open -a Simulator

# Or connect an iOS device

# Run in debug mode
flutter run
```

### Release Build

```bash
# Build release iOS app
flutter build ios --release --obfuscate --split-debug-info=build/debug-info
```

### App Store Build

1. **Open Xcode**:

```bash
open ios/Runner.xcworkspace
```

2. **Configure signing**:
   - Select the Runner project in Xcode
   - Go to Signing & Capabilities
   - Select your development team
   - Configure bundle identifier: `com.onetimesecret.app`

3. **Build for App Store**:
   - In Xcode, select Product > Archive
   - Once complete, click "Distribute App"
   - Follow the App Store upload wizard

### Certificate Pinning (Production)

For production builds, update certificate pins in `lib/core/constants/app_constants.dart`:

```dart
static const List<String> certificatePins = [
  'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
];
```

To get the certificate fingerprint:

```bash
# For a domain
openssl s_client -connect onetimesecret.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

## Security Considerations

### 1. Code Obfuscation

All release builds should use the `--obfuscate` flag:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### 2. Secure Storage

The app uses:
- **iOS**: Keychain with `first_unlock_this_device` accessibility
- **Android**: EncryptedSharedPreferences with AES-GCM encryption

### 3. Network Security

- HTTPS enforcement is configured via `NSAppTransportSecurity` (iOS) and `usesCleartextTraffic=false` (Android)
- Certificate pinning is implemented for production builds
- API communication uses Dio with custom security interceptors

### 4. Screenshot Protection

For production, consider implementing platform-specific code to disable screenshots:

**Android**: Add to `MainActivity.kt`:
```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    )
}
```

**iOS**: Add to `AppDelegate.swift`:
```swift
override func applicationWillResignActive(_ application: UIApplication) {
    let blurEffect = UIBlurEffect(style: .light)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = window?.frame ?? CGRect.zero
    blurView.tag = 1234
    window?.addSubview(blurView)
}
```

## Testing

### Run Unit Tests

```bash
flutter test
```

### Run Integration Tests

```bash
flutter test integration_test/
```

### Code Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/build.yml`:

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze

  build-android:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release

  build-ios:
    runs-on: macos-latest
    needs: test
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
```

## Troubleshooting

### Common Issues

1. **"Flutter SDK not found"**
   - Ensure Flutter is in your PATH
   - Run `flutter doctor` to verify installation

2. **"Pod install failed"** (iOS)
   - Navigate to `ios/` directory
   - Run `pod install --repo-update`

3. **"Gradle build failed"** (Android)
   - Clean the build: `flutter clean && flutter pub get`
   - Rebuild: `flutter build apk`

4. **Code generation issues**
   - Run: `flutter pub run build_runner clean`
   - Then: `flutter pub run build_runner build --delete-conflicting-outputs`

## Support

For issues and questions:
- GitHub Issues: https://github.com/onetimesecret/ots1/issues
- Documentation: https://docs.onetimesecret.dev/

## License

MIT License - see LICENSE file for details
