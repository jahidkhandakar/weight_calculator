// lib/utils/errors/error_handler.dart
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import 'app_exception.dart';
import '../ui/snackbar_service.dart';

typedef LogoutCallback = Future<void> Function({bool silent});

/// The only place that shows snackbars for errors.
/// Services/Repositories must NEVER show snackbars; they should throw AppException.
class ErrorHandler {
  ErrorHandler._();
  static final ErrorHandler I = ErrorHandler._();

  /// Inject from AuthController/AuthService (set once, e.g., in main.dart)
  LogoutCallback? onAuthExpired;

  bool _loggingOut = false;

  /// Use this in every catch:  `catch (e, st) => ErrorHandler.I.handle(e, stack: st);`
  void handle(Object error, {StackTrace? stack}) {
    final ex = _asAppException(error);

    // Debug log
    if (kDebugMode) {
      dev.log(
        '[ErrorHandler] code=${ex.code} status=${ex.httpStatus} '
        'title="${ex.title}" user="${ex.userMessage}"',
        name: 'ErrorHandler',
        error: ex.original ?? ex,
        stackTrace: stack,
      );
    }

    // Show exactly ONE professional snackbar for this error.
    SnackbarService.I.show(ex);

    // Special flow: AUTH_EXPIRED -> one silent logout/navigation
    if (ex.code == 'AUTH_EXPIRED' && onAuthExpired != null) {
      if (_loggingOut) return; // collapse repeated events
      _loggingOut = true;
      onAuthExpired!(silent: true).whenComplete(() {
        _loggingOut = false;
      });
    }
  }

  /// Map anything to AppException without importing the mapper here (avoid cycles).
  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    // If any service forgot to wrap with ErrorMapper, keep UX consistent:
    return AppException.unknown(original: error);
  }
}
