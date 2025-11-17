# Onetimesecret Mobile App

A secure, privacy-first Flutter mobile application for [Onetimesecret](https://onetimesecret.com) - enabling secure sharing of sensitive information with one-time access.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-blue.svg)](https://dart.dev)

## Features

- **Secure Secret Sharing**: Create one-time secrets that self-destruct after viewing
- **End-to-End Encryption**: All secrets are encrypted in transit and at rest
- **Passphrase Protection**: Add an extra layer of security with optional passphrases
- **Configurable Expiration**: Set custom time-to-live (TTL) for secrets
- **Platform Security**:
  - iOS: Keychain integration with biometric protection
  - Android: KeyStore with hardware-backed encryption
- **Certificate Pinning**: Enhanced security against man-in-the-middle attacks
- **Code Obfuscation**: Production builds use ProGuard (Android) and optimizations (iOS)
- **Clean Architecture**: Testable, maintainable codebase following Flutter best practices

## Screenshots

*Note: Add screenshots of your app here*

## Architecture

The application follows clean architecture principles with clear separation of concerns:

```
lib/
├── core/                    # Core functionality
│   ├── config/             # App configuration
│   ├── constants/          # Constants and app-wide values
│   ├── errors/             # Error handling
│   ├── network/            # Network layer (HTTP client, API client)
│   └── security/           # Security features
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   │   ├── data/          # Data layer (repositories, models)
│   │   ├── domain/        # Domain layer (entities, use cases)
│   │   └── presentation/  # Presentation layer (UI, state)
│   └── secrets/           # Secret management
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/                # Shared utilities
    ├── models/
    ├── providers/         # Riverpod providers
    ├── services/          # Shared services
    └── widgets/           # Reusable widgets
```

### Key Architectural Decisions

1. **Layered Architecture**: Separation of data, domain, and presentation layers
2. **Repository Pattern**: Abstract data sources for testability
3. **Dependency Injection**: Using GetIt for service location
4. **State Management**: Riverpod for reactive state management
5. **Error Handling**: Either monad pattern (using dartz) for functional error handling

## Security Features

### 1. Secure Storage
- **iOS**: Uses Keychain with `first_unlock_this_device` accessibility level
- **Android**: EncryptedSharedPreferences with AES-GCM encryption
- **Implementation**: `flutter_secure_storage` package

### 2. Network Security
- HTTPS enforcement (no cleartext traffic allowed)
- Certificate pinning for production builds
- Timeout configurations to prevent hanging connections
- Custom HTTP client with security interceptors

### 3. Code Protection
- ProGuard rules for Android (minification, obfuscation)
- `--obfuscate` flag for Flutter builds
- Stripped debug symbols in release builds
- Symbol maps stored separately for crash reporting

### 4. API Security
- API key stored in secure storage (never in plaintext)
- Authorization headers added automatically
- Token management with secure refresh flow

### 5. Platform-Specific Security
- No screenshots in sensitive screens (production)
- Biometric authentication support
- App integrity checks
- Root/jailbreak detection (optional)

## Getting Started

### Prerequisites

- Flutter 3.38 or higher
- Dart 3.10 or higher
- For iOS: Xcode 15+, CocoaPods
- For Android: Android Studio, JDK 8+

### Installation

1. **Clone the repository**:
```bash
git clone https://github.com/onetimesecret/ots1.git
cd ots1
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Run the app**:
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

For detailed build instructions, see [BUILD_GUIDE.md](BUILD_GUIDE.md).

## Configuration

### API Configuration

Update API settings in `lib/core/constants/app_constants.dart`:

```dart
static const String apiBaseUrl = 'https://onetimesecret.com';
static const String apiVersion = 'v2';
```

### Certificate Pinning

For production, add certificate pins in `lib/core/constants/app_constants.dart`:

```dart
static const List<String> certificatePins = [
  'sha256/YOUR_CERTIFICATE_PIN_HERE',
];
```

## Usage

### 1. Authentication

Launch the app and enter your Onetimesecret credentials:
- Username
- API Key (get from https://onetimesecret.com/account)

### 2. Create a Secret

1. Tap "Create Secret"
2. Enter your secret message
3. (Optional) Add a passphrase for extra security
4. (Optional) Specify recipient email
5. Choose expiration time
6. Tap "Create Secret"
7. Share the generated link

### 3. View a Secret

1. Tap "View Secret"
2. Enter the secret key (or paste the full URL)
3. If required, enter the passphrase
4. View the secret (it will be burned immediately)

## Development

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/auth_repository_test.dart

# With coverage
flutter test --coverage
```

### Code Generation

If you add new models or providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting

```bash
flutter analyze
```

The project uses `very_good_analysis` for strict linting rules.

## Project Structure

### Core Services

- **SecureStorageService** (`lib/shared/services/secure_storage_service.dart`): Handles secure data storage
- **ApiClient** (`lib/core/network/api_client.dart`): HTTP client with security features
- **HttpClientFactory** (`lib/core/network/http_client_factory.dart`): Creates configured HTTP clients

### Features

#### Authentication
- Login with API credentials
- Secure credential storage
- Session management
- Logout functionality

#### Secrets
- Create one-time secrets
- Retrieve secrets
- Passphrase protection
- Configurable TTL
- Burn secrets

## API Integration

The app integrates with Onetimesecret API v2. Key endpoints:

- `POST /api/v2/share` - Create a secret
- `POST /api/v2/secret/:key` - Retrieve a secret
- `POST /api/v2/private/:key` - Get metadata
- `POST /api/v2/private/:key/burn` - Burn a secret

For full API documentation, see https://docs.onetimesecret.dev/

## Testing

### Test Coverage

- Unit tests for repositories, services, and business logic
- Widget tests for UI components
- Integration tests for end-to-end workflows

### Running Tests

```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

## Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write or update tests
5. Ensure all tests pass (`flutter test`)
6. Run the analyzer (`flutter analyze`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

### Code Style

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use the provided `analysis_options.yaml` configuration
- Keep lines under 80 characters when practical
- Write clear, self-documenting code
- Add comments for complex logic

## Roadmap

- [ ] Biometric authentication
- [ ] Offline mode with local encryption
- [ ] Dark mode theme
- [ ] Multi-language support
- [ ] QR code generation/scanning
- [ ] Secret history (metadata only)
- [ ] Push notifications for secret access
- [ ] Widget for quick secret creation

## Inspiration

This app draws security architecture inspiration from:
- [ProtonMail](https://proton.me/mail) - Privacy-first design
- [Signal](https://signal.org) - End-to-end encryption
- [1Password](https://1password.com) - Secure storage patterns

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Onetimesecret](https://onetimesecret.com) for the excellent API
- Flutter team for the amazing framework
- All contributors to the open-source packages used in this project

## Support

- **Issues**: https://github.com/onetimesecret/ots1/issues
- **Documentation**: https://docs.onetimesecret.dev/
- **Website**: https://onetimesecret.com

## Disclaimer

This application is not officially affiliated with Onetimesecret. It is an independent open-source client built using the public API.

---

**Built with Flutter**