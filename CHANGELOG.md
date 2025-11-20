# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Security Improvements
- **Certificate Pinning Service**: Proper implementation of SSL/TLS certificate validation
  - Environment-based validation (strict in production, lenient in debug)
  - Automatic certificate fingerprint extraction for configuration
  - SHA-256 fingerprint matching against allowed certificates
  - See: `lib/core/security/certificate_pinning_service.dart`

#### Environment Configuration
- **Multi-Environment Support**: Development, staging, and production environments
  - Environment-specific API base URLs
  - Dynamic timeout configurations
  - Environment-based security settings (certificate pinning, RASP, logging)
  - Launch with `flutter run --dart-define=ENV=production`
  - See: `lib/core/config/environment.dart`

#### Developer Experience
- **Setup Script**: Automated project setup with `./setup.sh`
  - Checks Flutter/Dart installation
  - Runs code generation automatically
  - Installs dependencies
  - Platform-specific setup (CocoaPods for iOS)
  - Configuration validation

#### Testing
- **Integration Tests**: End-to-end test suite for critical flows
  - App launch and navigation tests
  - Create secret flow tests (validation, form interaction)
  - Reveal secret flow tests (QR scanning, passphrase)
  - Login flow tests (validation, skip login)
  - UI responsiveness tests (back navigation, screen sizes)
  - Run with: `flutter test integration_test/`
  - See: `integration_test/app_test.dart`

#### User Experience
- **Improved Error Messages**: User-friendly error messages with actionable guidance
  - Network errors with retry suggestions
  - Authentication errors with credential help
  - Secret not found with explanation
  - Rate limit errors with wait time
  - See: `lib/core/utils/error_message_helper.dart`

#### Logging & Debugging
- **Standardized Logging**: Application-wide logging utility
  - Environment-based log levels
  - Specialized logging methods (network, auth, security, storage)
  - Pretty-printed logs in debug mode
  - Error-only logs in production
  - See: `lib/core/utils/app_logger.dart`

#### Accessibility
- **Accessible Widgets**: Screen reader friendly components
  - `AccessibleIcon`: Icons with semantic labels
  - `AccessibleButton`: Buttons with proper semantics
  - `AccessibleCard`: Interactive cards with focus support
  - `AccessibleTextField`: Form fields with proper labeling
  - `AccessibleLoadingIndicator`: Loading states with announcements
  - `AccessibleError`: Error displays with semantic information
  - See: `lib/presentation/widgets/accessible_icon.dart`

### Changed

- **DioClient**: Updated to use `CertificatePinningService` for validation
- **AppConstants**: Now uses `EnvironmentConfig` for dynamic configuration
- **Certificate Validation**: Changed from accepting all certificates to proper validation

### Fixed

- **Certificate Pinning**: No longer accepts all certificates by default
- **Environment Configuration**: API URLs and timeouts are now environment-specific
- **Debug Logging**: Properly respects environment settings

### Security

- **Production Mode**: Certificate pinning is now enforced in production builds
- **Development Mode**: Certificate validation is lenient but logs fingerprints for configuration
- **Environment Separation**: Clear separation between dev, staging, and production security settings

## [1.0.0] - 2025-11-17

### Added

- Initial release of OneTimeSecret Flutter mobile application
- Clean architecture with Domain, Data, and Presentation layers
- BLoC pattern for state management
- Secure storage for credentials (Keychain/EncryptedSharedPreferences)
- OneTimeSecret API v2 integration
- Create and reveal secrets functionality
- QR code generation and scanning
- Runtime Application Self-Protection (RASP)
- Code obfuscation for Android and iOS
- Comprehensive documentation (README.md, BUILD.md)
- Unit and widget tests
- Platform-specific configurations (Android, iOS, iPadOS)

---

## How to Use This Changelog

### For Developers
- Review changes before pulling updates
- Check "Added" section for new features
- Check "Changed" section for API/behavior changes
- Check "Security" section for security-related updates

### For Users
- "Added": New features available
- "Changed": Changes to existing functionality
- "Fixed": Bug fixes

### Version Numbers
- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backward compatible
- **Patch** (0.0.X): Bug fixes, backward compatible
