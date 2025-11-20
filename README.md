# OneTimeSecret Flutter Mobile Application

A security and privacy-first Flutter mobile application for [OneTimeSecret](https://onetimesecret.com), enabling secure sharing of sensitive information through self-destructing, one-time-use secrets.

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

OneTimeSecret Flutter is a mobile application that allows users to create, share, and reveal secrets that automatically self-destruct after being read. Built with security-first principles, it implements industry-standard encryption, secure storage, and runtime protection mechanisms.

### Key Features

- **Create Secrets**: Share sensitive information with time-to-live (TTL) expiration
- **Passphrase Protection**: Optional passphrase encryption for additional security
- **QR Code Sharing**: Generate and scan QR codes for easy secret sharing
- **Self-Destructing Links**: Secrets are automatically destroyed after being viewed once
- **Secure Storage**: Platform-specific encrypted storage (Keychain/EncryptedSharedPreferences)
- **Certificate Pinning**: Enhanced network security for API communications
- **Runtime Protection**: RASP (Runtime Application Self-Protection) enabled
- **Clean Architecture**: Maintainable, testable codebase with clear separation of concerns

## Architecture

This application follows **Clean Architecture** principles with three distinct layers:

```
┌─────────────────────────────────────────┐
│        Presentation Layer               │
│    (BLoC, Pages, Widgets)              │
├─────────────────────────────────────────┤
│         Domain Layer                    │
│  (Entities, Use Cases, Repositories)   │
├─────────────────────────────────────────┤
│          Data Layer                     │
│   (API Client, Models, Repositories)   │
└─────────────────────────────────────────┘
```

### Project Structure

```
lib/
├── config/              # Application configuration
│   ├── dependency_injection.dart
│   ├── router.dart
│   └── theme.dart
├── core/                # Core utilities and shared code
│   ├── constants/       # App and API constants
│   ├── errors/          # Error handling (failures, exceptions)
│   ├── network/         # Network utilities (DIO client)
│   ├── security/        # Security utilities (encryption, RASP)
│   └── storage/         # Secure storage service
├── data/                # Data layer
│   ├── datasources/     # API clients (Retrofit)
│   ├── models/          # Data models (DTOs)
│   └── repositories/    # Repository implementations
├── domain/              # Domain layer
│   ├── entities/        # Business entities
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Business logic use cases
└── presentation/        # Presentation layer
    ├── blocs/           # State management (BLoC)
    ├── pages/           # UI screens
    └── widgets/         # Reusable widgets
```

## Technology Stack

### Core
- **Flutter**: 3.38+ (Impeller rendering engine)
- **Dart**: 3.10+
- **State Management**: BLoC (flutter_bloc)
- **Dependency Injection**: get_it + injectable

### Networking & API
- **HTTP Client**: Dio
- **REST Client**: Retrofit
- **Certificate Pinning**: http_certificate_pinning
- **Connectivity**: connectivity_plus

### Security
- **Secure Storage**: flutter_secure_storage (Keychain/EncryptedSharedPreferences)
- **Encryption**: crypto, encrypt, pointycastle
- **RASP**: freerasp (Runtime Application Self-Protection)

### UI Components
- **Fonts**: Google Fonts (Inter)
- **QR Codes**: qr_flutter, mobile_scanner
- **Sharing**: share_plus
- **Icons**: Cupertino Icons

### Testing
- **Unit Testing**: flutter_test, mockito
- **BLoC Testing**: bloc_test
- **Integration Testing**: integration_test

## Getting Started

### Prerequisites

- Flutter SDK 3.38.0 or higher
- Dart SDK 3.10.0 or higher
- Android Studio (for Android development)
- Xcode 15.0+ (for iOS/iPadOS development, macOS only)

### Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd onetimesecret_flutter
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Generate required files**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run the app**

```bash
# Debug mode
flutter run

# Specific device
flutter run -d <device-id>

# Release mode
flutter run --release
```

## Build & Deployment

For detailed build and deployment instructions, see [BUILD.md](BUILD.md).

### Quick Build Commands

#### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Release App Bundle (Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

#### iOS/iPadOS

```bash
# Debug build
flutter build ios --debug --no-codesign

# Release build
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
```

## Testing

### Run Tests

```bash
# All tests
flutter test

# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
```

### Test Coverage

```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## API Integration

This application integrates with the **OneTimeSecret API v2**. Key endpoints:

- `POST /api/v2/share` - Create a new secret
- `POST /api/v2/secret/:key` - Reveal a secret (consumes it)
- `POST /api/v2/private/:key/burn` - Manually destroy a secret
- `GET /api/v2/private/recent` - Get recent secrets (authenticated)
- `GET /api/v2/status` - API health check

### Authentication

The API supports two modes:

1. **Anonymous**: Limited functionality, no authentication required
2. **Authenticated**: Full access using Basic Auth (username:apikey)

Get API credentials at [onetimesecret.com/account](https://onetimesecret.com/account)

## Security Features

### 1. Secure Storage

- **iOS**: Keychain Services with biometric protection
- **Android**: EncryptedSharedPreferences with AES-256 encryption

### 2. Certificate Pinning

SSL/TLS certificate validation to prevent man-in-the-middle attacks.

### 3. Code Obfuscation

- **Android**: ProGuard rules configured
- **iOS**: Symbol stripping and bitcode enabled

### 4. Runtime Application Self-Protection (RASP)

Detects and responds to:
- Root/Jailbreak detection
- Debug mode detection
- Hooking framework detection
- Emulator/Simulator detection
- App integrity checks

### 5. Network Security

- HTTPS enforced for all communications
- No cleartext traffic allowed
- TLS 1.2+ required
- Certificate validation with pinning

## Configuration

### API Base URL

Update in `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'https://onetimesecret.com';
```

### Certificate Pinning

Add certificate fingerprints in `lib/core/constants/app_constants.dart`:

```dart
static const List<String> allowedSHA256Fingerprints = [
  'sha256/YOUR_CERTIFICATE_FINGERPRINT',
];
```

### RASP Configuration

Update in `lib/core/security/rasp_config.dart`:

```dart
// Android signing certificate
signingCertHashes: ['YOUR_CERT_HASH'],

// iOS Team ID
teamId: 'YOUR_TEAM_ID',
```

## Development

### Code Generation

The project uses code generation for:

- **JSON Serialization**: `json_serializable`
- **API Client**: `retrofit_generator`
- **Dependency Injection**: `injectable_generator`
- **Test Mocks**: `mockito`

Run after modifying annotated classes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

### State Management

Uses **BLoC pattern** for predictable state management:

- `AuthBloc`: Authentication and user session
- `SecretBloc`: Secret creation, revelation, and management

### Dependency Injection

Uses `get_it` with `injectable` for clean dependency injection:

```dart
// Register dependencies
await configureDependencies();

// Access anywhere
final authBloc = getIt<AuthBloc>();
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow Flutter style guide and best practices
4. Write tests for new features
5. Ensure all tests pass (`flutter test`)
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` to check for issues
- Format code with `flutter format`
- Write meaningful commit messages

## Roadmap

- [ ] Biometric authentication
- [ ] Dark mode theme customization
- [ ] Offline secret creation with sync
- [ ] Secret expiration notifications
- [ ] Multiple API endpoint support
- [ ] Secret templates
- [ ] Batch secret operations
- [ ] Export/backup functionality
- [ ] Multi-language support (i18n)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OneTimeSecret](https://onetimesecret.com) for the excellent secret-sharing service
- [Flutter](https://flutter.dev) team for the amazing framework
- Open-source community for security best practices and libraries

## Support

- **Documentation**: See [BUILD.md](BUILD.md) for detailed build instructions
- **Issues**: Report bugs via GitHub Issues
- **Security**: Report security vulnerabilities privately to the maintainers

## Disclaimer

This application is a client implementation for OneTimeSecret. Use at your own risk. Always verify the security requirements for your specific use case.

---

**Built with ❤️ using Flutter**

For questions or support, please open an issue on GitHub.
