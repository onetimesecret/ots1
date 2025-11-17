import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Certificate pinning utility for validating SSL/TLS certificates
class CertificatePinningService {
  /// Validate certificate against pinned fingerprints
  static bool validateCertificate(X509Certificate cert, String host, int port) {
    // In debug mode, be more lenient but still log
    if (kDebugMode && !AppConstants.enableCertificatePinning) {
      debugPrint('⚠️ Certificate validation bypassed in debug mode');
      debugPrint('Certificate from $host:$port');
      debugPrint('Issuer: ${cert.issuer}');
      debugPrint('Subject: ${cert.subject}');
      return true;
    }

    // Calculate SHA-256 fingerprint of the certificate
    final fingerprint = _getCertificateFingerprint(cert);

    // Check if fingerprint is in allowed list
    final isValid = AppConstants.allowedSHA256Fingerprints.isNotEmpty
        ? AppConstants.allowedSHA256Fingerprints.contains(fingerprint)
        : true; // Allow all if no pins configured (should be temporary)

    if (!isValid) {
      debugPrint('❌ Certificate validation failed for $host:$port');
      debugPrint('Expected one of: ${AppConstants.allowedSHA256Fingerprints}');
      debugPrint('Got: $fingerprint');
    } else if (kDebugMode) {
      debugPrint('✅ Certificate validated for $host:$port');
      debugPrint('Fingerprint: $fingerprint');
    }

    return isValid;
  }

  /// Calculate SHA-256 fingerprint of certificate
  static String _getCertificateFingerprint(X509Certificate cert) {
    try {
      final derBytes = cert.der;
      final digest = sha256.convert(derBytes);
      return 'sha256/${base64Encode(digest.bytes)}';
    } catch (e) {
      debugPrint('Error calculating certificate fingerprint: $e');
      return '';
    }
  }

  /// Get certificate details for debugging
  static Map<String, dynamic> getCertificateDetails(X509Certificate cert) {
    return {
      'issuer': cert.issuer,
      'subject': cert.subject,
      'startDate': cert.startValidity,
      'endDate': cert.endValidity,
      'fingerprint': _getCertificateFingerprint(cert),
    };
  }

  /// Extract and print certificate fingerprint (for configuration)
  static void printCertificateFingerprint(X509Certificate cert) {
    final fingerprint = _getCertificateFingerprint(cert);
    debugPrint('═══════════════════════════════════════');
    debugPrint('Certificate Fingerprint (SHA-256)');
    debugPrint('Add this to allowedSHA256Fingerprints:');
    debugPrint('  \'$fingerprint\',');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Certificate Details:');
    debugPrint('  Issuer: ${cert.issuer}');
    debugPrint('  Subject: ${cert.subject}');
    debugPrint('  Valid From: ${cert.startValidity}');
    debugPrint('  Valid To: ${cert.endValidity}');
    debugPrint('═══════════════════════════════════════');
  }
}
