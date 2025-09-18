// lib/utils/errors/app_exception.dart
import 'dart:core';

enum ErrorSeverity { info, warning, error, critical }

/// The single error type your UI handles.
/// Always throw/catch this (directly or via ErrorMapper).
class AppException implements Exception {
  final String code;        // stable internal code (e.g., AUTH_EXPIRED)
  final String title;       // short UI title
  final String userMessage; // human text for snackbar
  final ErrorSeverity severity;
  final int? httpStatus;
  final Object? original;   // raw error/response for logs

  const AppException({
    required this.code,
    required this.title,
    required this.userMessage,
    this.severity = ErrorSeverity.error,
    this.httpStatus,
    this.original,
  });

  // -------- Common factories --------
  factory AppException.authExpired({Object? original}) => AppException(
        code: 'AUTH_EXPIRED',
        title: 'Signed out',
        userMessage: 'Your session expired. Please sign in again.',
        severity: ErrorSeverity.warning,
        httpStatus: 401,
        original: original,
      );

  factory AppException.network({Object? original}) => AppException(
        code: 'NETWORK_ERROR',
        title: 'No internet',
        userMessage: 'Please check your internet connection and try again.',
        severity: ErrorSeverity.error,
        original: original,
      );

  factory AppException.timeout({Object? original}) => AppException(
        code: 'TIMEOUT',
        title: 'Taking too long',
        userMessage: 'The server took too long to respond. Please try again.',
        severity: ErrorSeverity.error,
        original: original,
      );

  factory AppException.server({Object? original, int? status}) => AppException(
        code: 'SERVER_ERROR',
        title: 'Server error',
        userMessage: 'Our server had a problem. Please try again later.',
        severity: ErrorSeverity.error,
        httpStatus: status,
        original: original,
      );

  factory AppException.client({String? message, Object? original, int? status}) =>
      AppException(
        code: 'CLIENT_ERROR',
        title: 'Request error',
        userMessage: (message?.trim().isNotEmpty ?? false)
            ? _ensurePeriod(message!.trim())
            : 'There was a problem with your request.',
        severity: ErrorSeverity.error,
        httpStatus: status,
        original: original,
      );

  factory AppException.unknown({Object? original}) => AppException(
        code: 'UNKNOWN',
        title: 'Something went wrong',
        userMessage: 'Unexpected error occurred. Please try again.',
        severity: ErrorSeverity.error,
        original: original,
      );

  // -------- Domain-specific factories (Weight Calculator) --------
  factory AppException.noCattleDetected({Object? original, int? status}) =>
      AppException(
        code: 'NO_CATTLE',
        title: 'Invalid photo',
        userMessage: 'Please upload a cattle photo.',
        severity: ErrorSeverity.warning,
        httpStatus: status ?? 400,
        original: original,
      );

  factory AppException.noMarkerDetected({Object? original, int? status}) =>
      AppException(
        code: 'NO_MARKER',
        title: 'Marker missing',
        userMessage: 'Please upload a photo with Aruco Marker.',
        severity: ErrorSeverity.warning,
        httpStatus: status ?? 400,
        original: original,
      );

  static String _ensurePeriod(String s) {
    return s.endsWith('.') ? s : '$s.';
  }

  @override
  String toString() =>
      'AppException($code, $userMessage, status=$httpStatus, original=$original)';
}
