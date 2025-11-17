# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in the One-Time Secret Mobile App, please report it by emailing the project maintainers.

**Please do not open a public issue for security vulnerabilities.**

### What to Include

When reporting a vulnerability, please include:

1. A description of the vulnerability
2. Steps to reproduce the issue
3. Potential impact of the vulnerability
4. Any suggested fixes (if available)

### Response Timeline

- **Initial Response**: Within 48 hours of report
- **Status Update**: Within 7 days of report
- **Fix Timeline**: Depends on severity, typically 14-30 days

## Security Best Practices for Users

1. **Keep the app updated**: Always use the latest version
2. **Secure your device**: Use device encryption and secure lock screens
3. **API credentials**: Never share your API credentials
4. **Network security**: Avoid using the app on untrusted networks
5. **Verify links**: Always verify secret links before retrieving

## Security Features

This app implements multiple security layers:

### Data Security
- Platform-specific secure storage (Keychain/Keystore)
- No sensitive data in logs
- Encrypted local storage for credentials

### Network Security
- HTTPS-only communication
- Certificate validation
- Timeout protection
- Request/response validation

### Code Security
- Release build obfuscation
- ProGuard/R8 optimization
- No hardcoded secrets
- Input validation and sanitization

## Acknowledgments

We appreciate responsible disclosure and will acknowledge security researchers who help improve the app's security (with permission).
