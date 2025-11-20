# OneTimeSecret Flutter App - Build Documentation

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Project Setup](#project-setup)
4. [Security Configuration](#security-configuration)
5. [Build Commands](#build-commands)
6. [Running Tests](#running-tests)
7. [Deployment](#deployment)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

- **Flutter SDK**: 3.38.0 or higher
- **Dart SDK**: 3.10.0 or higher
- **Android Studio**: Latest stable version (for Android development)
- **Xcode**: 15.0 or higher (for iOS/iPadOS development, macOS only)
- **Git**: Latest version

### Platform-Specific Requirements

#### Android
- Android SDK 24 (Android 7.0) or higher
- Android SDK Build-Tools
- Android SDK Platform-Tools
- Java JDK 17 or higher

#### iOS/iPadOS
- macOS 13.0 (Ventura) or higher
- CocoaPods 1.12.0 or higher
- Apple Developer Account (for device deployment)

---

## Environment Setup

### 1. Install Flutter

```bash
# Download and install Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor -v
```

### 2. Configure Flutter

```bash
# Enable required platforms
flutter config --enable-android
flutter config --enable-ios

# Accept Android licenses
flutter doctor --android-licenses
```

### 3. Install Dependencies

```bash
# Navigate to project directory
cd onetimesecret_flutter

# Get Flutter dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Project Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd onetimesecret_flutter
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Required Files

The project uses code generation for JSON serialization, Retrofit API client, and dependency injection.

```bash
# Generate all required files
flutter pub run build_runner build --delete-conflicting-outputs

# For continuous generation during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Configure API Credentials

Update the base URL in `lib/core/constants/app_constants.dart` if using a custom OneTimeSecret instance:

```dart
static const String baseUrl = 'https://onetimesecret.com'; // Change as needed
```

---

## Security Configuration

### 1. Certificate Pinning

#### For Production

1. Obtain SSL certificate fingerprints for `onetimesecret.com`:

```bash
# Get certificate fingerprint
openssl s_client -connect onetimesecret.com:443 < /dev/null 2>/dev/null | \
  openssl x509 -fingerprint -sha256 -noout -in /dev/stdin
```

2. Update `lib/core/constants/app_constants.dart`:

```dart
static const List<String> allowedSHA256Fingerprints = [
  'sha256/YOUR_CERTIFICATE_FINGERPRINT_HERE',
];
```

3. Update Android network security config in `android/app/src/main/res/xml/network_security_config.xml`

4. Configure iOS ATS settings in `ios/Runner/Info.plist`

### 2. Code Obfuscation

#### Android

ProGuard rules are already configured in `android/app/proguard-rules.pro`.

#### iOS

Obfuscation is enabled automatically in release builds.

### 3. Runtime Application Self-Protection (RASP)

Update RASP configuration in `lib/core/security/rasp_config.dart`:

```dart
// Android
signingCertHashes: [
  'YOUR_SIGNING_CERTIFICATE_HASH',
],

// iOS
teamId: 'YOUR_APPLE_TEAM_ID',
```

---

## Build Commands

### Development Builds

#### Android Debug

```bash
# Build APK
flutter build apk --debug

# Install on connected device
flutter install

# Run on emulator/device
flutter run
```

#### iOS Debug

```bash
# Build for iOS
flutter build ios --debug --no-codesign

# Run on simulator
flutter run -d "iPhone 15 Pro"

# Run on device
flutter run -d <device-id>
```

### Release Builds

#### Android Release

```bash
# Build release APK
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Output location:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

**Important**: Configure signing before building release:

1. Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=<alias>
storeFile=<path-to-keystore>
```

2. Update `android/app/build.gradle` to reference the keystore.

#### iOS Release

```bash
# Build release IPA
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols

# Build for specific device (iPad)
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
```

**Important**: Configure Xcode project:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select signing team
3. Configure provisioning profiles
4. Archive and upload to App Store Connect

---

## Running Tests

### Unit Tests

```bash
# Run all unit tests
flutter test test/unit/

# Run specific test file
flutter test test/unit/domain/usecases/create_secret_usecase_test.dart

# Run with coverage
flutter test --coverage
```

### Widget Tests

```bash
# Run widget tests
flutter test test/widget/
```

### Integration Tests

```bash
# Run integration tests on connected device
flutter test integration_test/
```

### Generate Test Coverage Report

```bash
# Generate coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

---

## Deployment

### Android - Google Play Store

1. **Prepare Release Build**

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

2. **Upload to Play Console**

- Navigate to Google Play Console
- Create new release
- Upload `build/app/outputs/bundle/release/app-release.aab`
- Complete release form and submit

### iOS - App Store

1. **Prepare Release Build**

```bash
flutter build ios --release \
  --obfuscate \
  --split-debug-info=build/ios/outputs/symbols
```

2. **Archive in Xcode**

- Open `ios/Runner.xcworkspace`
- Product > Archive
- Distribute App > App Store Connect
- Follow prompts to upload

### iPadOS - App Store

Same process as iOS. The app supports iPad layouts automatically.

---

## Troubleshooting

### Common Issues

#### 1. Build Runner Fails

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. Dependency Conflicts

```bash
# Update dependencies
flutter pub upgrade

# Reset pub cache
flutter pub cache repair
```

#### 3. iOS Pod Install Fails

```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### 4. Android Build Fails

```bash
# Clean Android build
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 5. Certificate Pinning Issues

- Verify certificate fingerprints are correct
- Check network security configuration
- Ensure HTTPS is enforced
- Test with certificate pinning disabled in development

### Getting Help

- **Flutter Documentation**: https://docs.flutter.dev
- **OneTimeSecret API Docs**: https://docs.onetimesecret.com
- **Project Issues**: Create an issue in the repository

---

## Additional Resources

### Code Generation

This project uses several code generation tools:

- `json_serializable`: JSON serialization/deserialization
- `retrofit_generator`: REST API client generation
- `injectable_generator`: Dependency injection
- `mockito`: Test mock generation

Run code generation after modifying:
- Data models (*.dart files with @JsonSerializable)
- API endpoints (onetimesecret_api.dart)
- Injectable classes (@injectable, @singleton)

### Architecture Overview

```
lib/
├── config/           # App configuration (DI, routing, theme)
├── core/             # Core utilities, constants, errors
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── security/
│   └── storage/
├── data/             # Data layer
│   ├── datasources/  # API clients
│   ├── models/       # DTOs
│   └── repositories/ # Repository implementations
├── domain/           # Domain layer
│   ├── entities/     # Business entities
│   ├── repositories/ # Repository interfaces
│   └── usecases/     # Business logic
└── presentation/     # Presentation layer
    ├── blocs/        # State management
    ├── pages/        # UI screens
    └── widgets/      # Reusable widgets
```

### Security Best Practices

1. **Never commit sensitive data** (API keys, certificates)
2. **Use environment variables** for configuration
3. **Enable code obfuscation** for production builds
4. **Implement certificate pinning** for API communications
5. **Use secure storage** for credentials
6. **Enable RASP** for runtime protection
7. **Regular security audits** of dependencies

### Performance Optimization

1. **Use const constructors** where possible
2. **Lazy-load heavy dependencies**
3. **Optimize images** before including in assets
4. **Profile app performance** regularly
5. **Monitor memory usage** and fix leaks
6. **Use release builds** for performance testing

---

## Build Configuration Summary

### Android

- **Min SDK**: 24 (Android 7.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34
- **Build Tools**: Latest
- **NDK**: Flutter NDK version
- **Obfuscation**: ProGuard (enabled in release)
- **Secure Storage**: EncryptedSharedPreferences

### iOS/iPadOS

- **Deployment Target**: 12.0
- **Xcode Version**: 15.0+
- **Swift Version**: 5.0
- **Secure Storage**: Keychain Services
- **Rendering**: Impeller (Flutter 3.38+)

---

**Last Updated**: 2025-11-17
**Version**: 1.0.0
