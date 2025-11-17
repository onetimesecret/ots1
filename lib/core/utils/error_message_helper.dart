import '../errors/failures.dart';

/// Helper class to convert failures to user-friendly error messages
class ErrorMessageHelper {
  ErrorMessageHelper._();

  /// Convert a Failure to a user-friendly message with actionable guidance
  static String getMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return _getNetworkFailureMessage(failure);
    } else if (failure is AuthenticationFailure) {
      return _getAuthenticationFailureMessage(failure);
    } else if (failure is SecretNotFoundFailure) {
      return _getSecretNotFoundMessage(failure);
    } else if (failure is RateLimitFailure) {
      return _getRateLimitMessage(failure);
    } else if (failure is ValidationFailure) {
      return _getValidationMessage(failure);
    } else if (failure is ServerFailure) {
      return _getServerFailureMessage(failure);
    } else if (failure is CertificatePinningFailure) {
      return _getCertificatePinningMessage(failure);
    } else if (failure is StorageFailure) {
      return _getStorageFailureMessage(failure);
    } else {
      return _getUnknownFailureMessage(failure);
    }
  }

  static String _getNetworkFailureMessage(NetworkFailure failure) {
    return 'No internet connection.\n\n'
        'Please check your network settings and try again.';
  }

  static String _getAuthenticationFailureMessage(
      AuthenticationFailure failure) {
    if (failure.code == 401) {
      return 'Invalid credentials.\n\n'
          'Please check your username and API key. '
          'Get your API credentials at onetimesecret.com/account';
    } else if (failure.code == 403) {
      return 'Access forbidden.\n\n'
          'Your account may not have permission for this action. '
          'Please verify your API credentials.';
    }
    return 'Authentication failed.\n\n'
        '${failure.message}\n\n'
        'Please verify your credentials and try again.';
  }

  static String _getSecretNotFoundMessage(SecretNotFoundFailure failure) {
    return 'Secret not found.\n\n'
        'This secret may have already been viewed and destroyed, '
        'or the link is invalid. Remember, secrets can only be viewed once!';
  }

  static String _getRateLimitMessage(RateLimitFailure failure) {
    return 'Rate limit exceeded.\n\n'
        'You\'ve made too many requests in a short time. '
        'Please wait a few minutes and try again.';
  }

  static String _getValidationMessage(ValidationFailure failure) {
    return 'Invalid input.\n\n'
        '${failure.message}\n\n'
        'Please check your input and try again.';
  }

  static String _getServerFailureMessage(ServerFailure failure) {
    if (failure.code != null && failure.code! >= 500) {
      return 'Server error.\n\n'
          'The OneTimeSecret server is experiencing issues. '
          'Please try again later.';
    }
    return 'An error occurred.\n\n'
        '${failure.message}\n\n'
        'Please try again or contact support if the problem persists.';
  }

  static String _getCertificatePinningMessage(
      CertificatePinningFailure failure) {
    return 'Connection not secure.\n\n'
        'Could not verify the server\'s security certificate. '
        'Please check your connection and try again.';
  }

  static String _getStorageFailureMessage(StorageFailure failure) {
    return 'Storage error.\n\n'
        'Could not access secure storage. '
        'Please check app permissions and try again.';
  }

  static String _getUnknownFailureMessage(Failure failure) {
    return 'Unexpected error.\n\n'
        '${failure.message}\n\n'
        'Please try again. If the problem persists, contact support.';
  }

  /// Get a short title for the failure (for snackbars)
  static String getShortMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection';
    } else if (failure is AuthenticationFailure) {
      return 'Authentication failed';
    } else if (failure is SecretNotFoundFailure) {
      return 'Secret not found';
    } else if (failure is RateLimitFailure) {
      return 'Rate limit exceeded';
    } else if (failure is ValidationFailure) {
      return 'Invalid input';
    } else if (failure is ServerFailure) {
      return 'Server error';
    } else if (failure is CertificatePinningFailure) {
      return 'Connection not secure';
    } else if (failure is StorageFailure) {
      return 'Storage error';
    } else {
      return 'Error occurred';
    }
  }

  /// Check if failure is retryable
  static bool isRetryable(Failure failure) {
    return failure is NetworkFailure ||
        failure is ServerFailure ||
        failure is RateLimitFailure;
  }

  /// Get retry action message
  static String? getRetryAction(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Retry when connected';
    } else if (failure is ServerFailure) {
      return 'Retry now';
    } else if (failure is RateLimitFailure) {
      return 'Retry later';
    }
    return null;
  }
}
