# One-Time Secret Mobile App

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A secure, privacy-focused Flutter mobile client for [One-Time Secret](https://onetimesecret.dev/) (OTS), enabling users to share sensitive information that self-destructs after being read.

## Features

- **Secure Secret Sharing**: Create one-time secrets with optional passphrase protection
- **Secret Retrieval**: Retrieve secrets using their unique keys
- **Time-to-Live (TTL)**: Configure how long secrets remain valid
- **End-to-End Security**: Built with security best practices from the ground up
- **Cross-Platform**: Supports Android, iOS, and iPadOS
- **Clean Architecture**: Modular, testable codebase following SOLID principles
- **Secure Storage**: Uses platform-specific secure storage (Android Keystore, iOS Keychain)
- **Modern UI**: Material Design 3 with dark mode support

## Architecture

This app follows **Clean Architecture** principles with three distinct layers:

```
lib/
├── core/                 # Core utilities and configurations
│   ├── config/          # App configuration
│   ├── constants/       # API constants and app-wide constants
│   ├── di/              # Dependency injection setup
│   ├── error/           # Error handling (exceptions, failures)
│   ├── network/         # HTTP client with error handling
│   └── security/        # Secure storage service
├── data/                # Data layer
│   ├── datasources/     # Remote data sources (API)
│   ├── models/          # Data models with JSON serialization
│   └── repositories/    # Repository implementations
├── domain/              # Domain layer (business logic)
│   ├── entities/        # Domain entities
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Use cases (business operations)
└── presentation/        # Presentation layer (UI)
    ├── providers/       # State management (Provider)
    ├── screens/         # UI screens
    └── widgets/         # Reusable widgets
```

## Security Features

### Platform Security
- **Android**: Uses Android Keystore for secure credential storage
- **iOS**: Uses iOS Keychain with `first_unlock` accessibility
- **Network Security**: Enforces HTTPS-only connections
- **Certificate Validation**: Proper TLS/SSL certificate validation
- **No Cleartext Traffic**: Network security config prevents cleartext HTTP

### Code Security
- **Obfuscation**: Release builds use code obfuscation (`--obfuscate`)
- **ProGuard**: Android release builds use ProGuard for additional protection
- **Secure Storage**: All sensitive data (API keys, tokens) stored in platform secure storage
- **No Logging**: Production builds avoid logging sensitive information
- **Input Validation**: All user inputs are validated before processing

### API Security
- **Basic Authentication**: Supports API key authentication
- **Timeout Protection**: Network requests have configurable timeouts
- **Error Handling**: Comprehensive error handling for all network operations

## Prerequisites

Since Flutter is not installed in the development environment, you'll need to set up Flutter on your local machine to build and run this app:

1. **Flutter SDK**: Install Flutter 3.0 or higher
   - Follow instructions at https://docs.flutter.dev/get-started/install

2. **Platform-Specific Requirements**:
   - **Android**: Android Studio with Android SDK (API 21+)
   - **iOS**: Xcode 14+ (macOS only)

3. **Dependencies**: All dependencies are declared in `pubspec.yaml`

## Installation & Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ots1
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Code

Generate JSON serialization code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure API (Optional)

To use authenticated API features, you can store your OTS API credentials:

The app will automatically use stored credentials for API requests. Credentials are stored securely using `flutter_secure_storage`.

## Building the App

### Development Build

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

### Release Build

**Android APK:**
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug_info
```

**Android App Bundle (for Google Play):**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug_info
```

**iOS:**
```bash
flutter build ipa --release --obfuscate --split-debug-info=build/debug_info
```

> **Note**: For iOS release builds, you'll need to configure code signing in Xcode.

## Configuration

### Android Configuration

- **Minimum SDK**: API 21 (Android 5.0)
- **Target SDK**: API 34 (Android 14)
- **Network Security**: `android/app/src/main/res/xml/network_security_config.xml`
- **ProGuard Rules**: `android/app/proguard-rules.pro`

### iOS Configuration

- **Minimum iOS Version**: 12.0
- **Supported Devices**: iPhone, iPad
- **Network Security**: Configured in `Info.plist` with `NSAppTransportSecurity`

## Dependencies

### Core Dependencies
- `flutter_secure_storage`: ^9.0.0 - Secure credential storage
- `http`: ^1.2.2 - HTTP client for API calls
- `get_it`: ^7.6.0 - Dependency injection
- `provider`: ^6.1.2 - State management
- `json_annotation`: ^4.8.0 - JSON serialization annotations

### Dev Dependencies
- `build_runner`: ^2.4.0 - Code generation
- `json_serializable`: ^6.7.0 - JSON serialization code generation
- `flutter_lints`: ^3.0.0 - Linting rules
- `flutter_test`: SDK - Testing framework

## API Integration

The app integrates with the OTS v2 API at `https://onetimesecret.dev/api/v2`.

### Supported Endpoints

- `POST /share` - Create a new secret
- `POST /secret/:key` - Retrieve and burn a secret
- `GET /secret/:key` - Get secret metadata
- `POST /generate` - Generate a random secret
- `GET /status` - Check API status

API constants are defined in `lib/core/constants/api_constants.dart`.

## Usage

### Creating a Secret

1. Launch the app
2. Tap "Create Secret"
3. Enter your secret message
4. Configure options (TTL, passphrase, recipient)
5. Tap "Create Secret"
6. Share the generated link with the recipient

### Retrieving a Secret

1. Launch the app
2. Tap "Retrieve Secret"
3. Enter the secret key (or paste the full URL)
4. If required, enter the passphrase
5. Tap "Retrieve Secret"
6. View and copy the secret (it will be immediately deleted)

## Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## Contributing

This is an open-source project. Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security Considerations

### Best Practices Implemented

1. **Secure Storage**: Never store sensitive data in SharedPreferences or plain files
2. **HTTPS Only**: All network communication uses HTTPS
3. **Certificate Pinning**: Can be enabled for additional security
4. **Code Obfuscation**: Release builds are obfuscated
5. **No Sensitive Logging**: Production builds don't log sensitive information
6. **Input Validation**: All inputs are validated and sanitized
7. **Error Handling**: Graceful error handling without exposing sensitive details

### Recommendations for Production

1. **Enable Certificate Pinning**: Implement certificate pinning for the OTS API
2. **Add Biometric Authentication**: Require biometric auth before accessing secrets
3. **Implement Rate Limiting**: Add client-side rate limiting for API calls
4. **Add Analytics**: Implement privacy-respecting analytics (if needed)
5. **Regular Security Audits**: Perform regular security audits and dependency updates
6. **Code Signing**: Properly configure code signing for both platforms

## Troubleshooting

### Common Issues

**1. Build fails with "Flutter SDK not found"**
- Ensure Flutter is installed and added to your PATH
- Run `flutter doctor` to verify installation

**2. Android build fails**
- Ensure Android SDK is installed
- Check that `minSdkVersion` is 21 or higher
- Run `flutter clean` and rebuild

**3. iOS build fails**
- Ensure Xcode is installed (macOS only)
- Run `pod install` in the `ios/` directory
- Check code signing configuration

**4. Network requests fail**
- Verify internet connection
- Check that HTTPS is being used
- Ensure network security config allows the domain

## Roadmap

- [ ] Biometric authentication
- [ ] Certificate pinning
- [ ] QR code generation/scanning for secret keys
- [ ] Secret history (local, encrypted)
- [ ] Custom TTL values
- [ ] Bulk secret operations
- [ ] i18n/l10n support
- [ ] Tablet-optimized UI
- [ ] Widget support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [One-Time Secret](https://onetimesecret.dev/) - The OTS service
- [Flutter](https://flutter.dev/) - The UI framework
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) - Secure storage plugin

## Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Built with Flutter and a focus on security and privacy.**
