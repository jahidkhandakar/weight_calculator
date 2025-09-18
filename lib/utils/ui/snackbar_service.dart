// lib/utils/ui/snackbar_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../errors/app_exception.dart';
import '../errors/error_messages.dart';

/// Single source of truth for snackbars; also de-dupes back-to-back duplicates.
class SnackbarService {
  SnackbarService._();
  static final SnackbarService I = SnackbarService._();

  String? _lastKey;
  DateTime? _lastTime;

  bool _shouldShow(String key, {Duration window = const Duration(seconds: 2)}) {
    final now = DateTime.now();
    if (_lastKey == key && _lastTime != null && now.difference(_lastTime!) < window) {
      return false; // suppress duplicate within window
    }
    _lastKey = key;
    _lastTime = now;
    return true;
  }

  void show(AppException e) {
    final locale = Get.locale;

    // Titles: i18n title if present, else exception title, else derived
    final i18nTitle = ErrorMessages.titleFor(e.code, locale);
    final title = _pickTitle(i18nTitle, e);

    // Messages:
    // IMPORTANT: For CLIENT_ERROR, ALWAYS prefer the exception's userMessage.
    // i18n for CLIENT_ERROR often contains a generic fallback which would mask specific backend details.
    String message;
    if (e.code == 'CLIENT_ERROR') {
      final m = _safe(e.userMessage);
      message = m.isNotEmpty ? m : 'There was a problem with your request.';
    } else {
      final i18nMessage = ErrorMessages.messageFor(e.code, locale);
      final m = _safe(i18nMessage);
      message = m.isNotEmpty ? m : (_safe(e.userMessage).isNotEmpty
          ? _safe(e.userMessage)
          : 'There was a problem with your request.');
    }

    // Dedupe key
    final key = '${e.code}|$title|$message';
    if (!_shouldShow(key)) return;

    // Close any open snackbar to avoid stacking
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundColor: _bgFor(e),
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }

  // ---------------- helpers ----------------

  String _pickTitle(String? i18nTitle, AppException e) {
    final tI18n = _safe(i18nTitle);
    if (tI18n.isNotEmpty) return tI18n;

    final tExc = _safe(e.title);
    if (tExc.isNotEmpty) return tExc;

    final tDerived = _safe(_derivedTitle(e));
    if (tDerived.isNotEmpty) return tDerived;

    return 'Error';
  }

  String _safe(String? s) => (s ?? '').trim();

  Color _bgFor(AppException e) {
    switch (e.severity) {
      case ErrorSeverity.info:
        return Colors.blueGrey.shade700;
      case ErrorSeverity.warning:
        return Colors.orange.shade700;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
      case ErrorSeverity.error:
      default:
        return Colors.red.shade700;
    }
  }

  String? _derivedTitle(AppException e) {
    final s = e.httpStatus;
    if (s != null) {
      if (s == 400) return 'Request error';
      if (s == 401 || s == 403) return 'Authorization error';
      if (s >= 500) return 'Server error';
    }
    switch (e.code) {
      case 'INVALID_CREDENTIALS':
        return 'Sign-in failed';
      case 'NO_MARKER':
        return 'Marker not detected';
      case 'NO_CATTLE':
        return 'No cattle detected';
      case 'INVALID_IMAGE':
        return 'Invalid image';
      case 'AUTH_EXPIRED':
        return 'Session expired';
      default:
        return null;
    }
  }
}
