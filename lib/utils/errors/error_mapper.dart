// lib/utils/errors/error_mapper.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_exception.dart';
import 'error_codes.dart';

/// Convert *anything* (exceptions, http responses, dio errors/responses) to AppException.
class ErrorMapper {
  static AppException toAppException(Object error, {int? statusCode}) {
    // Network / platform
    if (error is SocketException || error is HandshakeException) {
      return AppException.network(original: error);
    }
    if (error is TimeoutException) {
      return AppException.timeout(original: error);
    }
    if (error is FormatException) {
      return AppException.client(
        message: 'Invalid response format.',
        original: error,
        status: statusCode,
      );
    }
    if (error is HttpException || error is FileSystemException) {
      return AppException.unknown(original: error);
    }

    // Already normalized
    if (error is AppException) return error;

    // Try in order: DioException, Dio Response, http Response
    final fromDioEx = _mapFromDioException(error);
    if (fromDioEx != null) return fromDioEx;

    final fromDioResp = _mapFromDioResponse(error);
    if (fromDioResp != null) return fromDioResp;

    final fromHttpResponse = _mapFromHttpResponse(error);
    if (fromHttpResponse != null) return fromHttpResponse;

    // Fallback
    return AppException.unknown(original: error);
  }

  // ---------- Shared helpers ----------

  static String _stringifyBody(dynamic body) {
    if (body == null) return '';
    if (body is String) return body;
    if (body is List<int>) {
      try {
        return utf8.decode(body);
      } catch (_) {
        return body.toString();
      }
    }
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  static Map<String, dynamic> _toJsonIfPossible(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {}
    }
    return {};
  }

  /// Extract a human-facing error from arbitrary JSON (maps/lists/strings),
  /// prioritizing common signup/OTP fields.
  static String? _firstErrorFromJson(dynamic v, {int depth = 0}) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? null : s;
    }
    if (v is List) {
      for (final e in v) {
        final m = _firstErrorFromJson(e, depth: depth + 1);
        if (m != null) return m;
      }
      return null;
    }
    if (v is Map) {
      const preferredKeys = [
        'username', 'phone', 'phone_number',
        'password', 'new_password',
        'confirm_password', 'confirm_new_password',
        'name',
        'non_field_errors',
        'detail', 'message', 'error',
      ];
      for (final k in preferredKeys) {
        if (v.containsKey(k)) {
          final m = _firstErrorFromJson(v[k], depth: depth + 1);
          if (m != null) return m;
        }
      }
      for (final value in v.values) {
        final m = _firstErrorFromJson(value, depth: depth + 1);
        if (m != null) return m;
      }
      return null;
    }
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // ---------- package:http Response-like errors ----------

  static AppException? _mapFromHttpResponse(Object error) {
    try {
      final dyn = error as dynamic;
      final int status = dyn.statusCode as int;
      final String body = dyn.body is String ? dyn.body as String : _stringifyBody(dyn.body);

      final json = _toJsonIfPossible(body);
      final backendCode = (json['code'] ?? json['error_code'] ?? '').toString();
      String backendMsg = ((json['message'] ?? json['detail'] ?? json['error'])?.toString() ?? '').trim();

      // Field-level extraction (e.g., {"username":["already exists"]})
      backendMsg = backendMsg.isNotEmpty ? backendMsg : (_firstErrorFromJson(json) ?? '');

      final rawText = (backendMsg.isNotEmpty ? backendMsg : body).trim();
      final textForHeuristics = _stripHtml(rawText).toLowerCase();

      // 1) Domain mapping FIRST (even if 5xx)
      final domain = _mapDomain(
        backendCode,
        textForHeuristics,
        status: status,
        original: error,
        path: null,
      );
      if (domain != null) return domain;

      // 2) Auth
      if (status == 401 || status == 403) return AppException.authExpired(original: error);

      // 3) 4xx
      if (status >= 400 && status < 500) {
        return AppException.client(
          message: _humanize(rawText),
          original: error,
          status: status,
        );
      }

      // 4) 5xx
      if (status >= 500) return AppException.server(original: error, status: status);

      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------- DioException (no hard import needed) ----------

  static AppException? _mapFromDioException(Object error) {
    try {
      final typeName = error.runtimeType.toString(); // "DioException"
      if (!typeName.contains('Dio')) return null;

      final dyn = error as dynamic;
      final response = dyn.response;

      if (response == null) {
        final errType = (dyn.type?.toString() ?? '').toLowerCase();
        if (errType.contains('connection') || errType.contains('unknown')) {
          return AppException.network(original: error);
        }
        if (errType.contains('timeout')) {
          return AppException.timeout(original: error);
        }
        return AppException.unknown(original: error);
      }

      final int status = response.statusCode as int? ?? 0;
      final data = response.data;
      final path = (response.requestOptions?.path ?? '').toString();

      final json = _toJsonIfPossible(data);
      final bodyText = json.isNotEmpty ? jsonEncode(json) : _stringifyBody(data);

      final backendCode = (json['code'] ?? json['error_code'] ?? '').toString();
      String backendMsg = ((json['message'] ?? json['detail'] ?? json['error'])?.toString() ?? '').trim();

      // Field-level extraction
      backendMsg = backendMsg.isNotEmpty ? backendMsg : (_firstErrorFromJson(json) ?? '');

      final rawText = (backendMsg.isNotEmpty ? backendMsg : bodyText).trim();
      final textForHeuristics = _stripHtml(rawText).toLowerCase();

      // 1) Domain mapping FIRST
      final domain = _mapDomain(
        backendCode,
        textForHeuristics,
        status: status,
        original: error,
        path: path,
      );
      if (domain != null) return domain;

      // 2) Auth
      if (status == 401 || status == 403) return AppException.authExpired(original: error);

      // 3) 4xx
      if (status >= 400 && status < 500) {
        return AppException.client(
          message: _humanize(rawText),
          original: error,
          status: status,
        );
      }

      // 4) 5xx
      if (status >= 500) return AppException.server(original: error, status: status);

      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------- Dio Response<dynamic> passed directly ----------

  static AppException? _mapFromDioResponse(Object error) {
    try {
      final typeName = error.runtimeType.toString(); // "Response<dynamic>"
      if (!typeName.startsWith('Response')) return null;

      final dyn = error as dynamic;
      final int status = dyn.statusCode as int? ?? 0;
      final data = dyn.data;
      final path = (dyn.requestOptions?.path ?? '').toString();

      final json = _toJsonIfPossible(data);
      final bodyText = json.isNotEmpty ? jsonEncode(json) : _stringifyBody(data);

      final backendCode = (json['code'] ?? json['error_code'] ?? '').toString();
      String backendMsg = ((json['message'] ?? json['detail'] ?? json['error'])?.toString() ?? '').trim();

      // Field-level extraction
      backendMsg = backendMsg.isNotEmpty ? backendMsg : (_firstErrorFromJson(json) ?? '');

      final rawText = (backendMsg.isNotEmpty ? backendMsg : bodyText).trim();
      final textForHeuristics = _stripHtml(rawText).toLowerCase();

      // 1) Domain mapping FIRST
      final domain = _mapDomain(
        backendCode,
        textForHeuristics,
        status: status,
        original: error,
        path: path,
      );
      if (domain != null) return domain;

      // 2) Auth
      if (status == 401 || status == 403) return AppException.authExpired(original: error);

      // 3) 4xx
      if (status >= 400 && status < 500) {
        return AppException.client(
          message: _humanize(rawText),
          original: error,
          status: status,
        );
      }

      // 4) 5xx
      if (status >= 500) return AppException.server(original: error, status: status);

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Recognize weight-calculator domain errors and auth issues.
  static AppException? _mapDomain(
    String code,
    String message, {
    int? status,
    Object? original,
    String? path,
  }) {
    final c = code.trim().toUpperCase();
    final m = message.trim().toLowerCase();
    final p = (path ?? '').toLowerCase();

    // Prefer explicit backend codes
    if (c == BackendCodes.noMarker) {
      return AppException.noMarkerDetected(original: original, status: status);
    }
    if (c == BackendCodes.noCattle || c == BackendCodes.wrongObject) {
      return AppException.noCattleDetected(original: original, status: status);
    }
    if (c == BackendCodes.invalidImage) {
      return AppException(
        code: 'INVALID_IMAGE',
        title: 'Invalid image',
        userMessage: 'Please upload a clear cattle photo with the Aruco Marker.',
        httpStatus: status ?? 400,
        original: original,
      );
    }
    if (c == BackendCodes.tokenExpired ||
        c == BackendCodes.authInvalid ||
        c == BackendCodes.refreshInvalid) {
      return AppException.authExpired(original: original);
    }

    // ---------------- Heuristics on plain text/HTML ----------------

    // (A) Invalid credentials (login): show sign-in friendly message
    if (m.contains('no active account') ||
        m.contains('given credentials') ||
        m.contains('invalid credentials') ||
        m.contains('wrong password') ||
        m.contains('authentication failed') ||
        (p.contains('/auth/login') && (status == 401 || status == 403))) {
      return AppException(
        code: 'INVALID_CREDENTIALS',
        title: 'Sign-in failed',
        userMessage: 'Incorrect phone or password.',
        httpStatus: status ?? 401,
        original: original,
      );
    }

    // (B) Model pipeline blew up due to empty results (=> no detections)
    if (m.contains('index 0 is out of bounds') ||
        m.contains('index out of range') ||
        (m.contains('axis 0') && m.contains('size 0')) ||
        (m.contains('size 0') && (m.contains('array') || m.contains('axis'))) ||
        (m.contains('empty') && (m.contains('array') || m.contains('list') || m.contains('detections') || m.contains('result')))) {
      return AppException.noCattleDetected(original: original, status: status);
    }

    // (C) ArUco / marker missing
    if (m.contains('aruco') ||
        (m.contains('marker') &&
            (m.contains('missing') ||
                m.contains('not found') ||
                m.contains('absent') ||
                (m.contains('detect') && m.contains('fail'))))) {
      return AppException.noMarkerDetected(original: original, status: status);
    }

    // (D) No cattle detected / wrong object / detection failed
    if (m.contains('no cattle') ||
        m.contains('no cow') ||
        m.contains('cow not found') ||
        m.contains('cattle not found') ||
        m.contains('not a cattle') ||
        m.contains('not cattle') ||
        m.contains('wrong object') ||
        m.contains('no object') ||
        m.contains('nothing found') ||
        (m.contains('detect') && m.contains('fail')) ||
        (m.contains('object') && m.contains('not') && (m.contains('cow') || m.contains('cattle')))) {
      return AppException.noCattleDetected(original: original, status: status);
    }

    // (E) Bad/invalid image
    if (m.contains('invalid image') ||
        m.contains('unsupported') ||
        m.contains('decode error') ||
        m.contains('cannot read image') ||
        m.contains('bad image') ||
        m.contains('corrupt image')) {
      return AppException(
        code: 'INVALID_IMAGE',
        title: 'Invalid image',
        userMessage: 'Please upload a clear cattle photo with the Aruco Marker.',
        httpStatus: status ?? 400,
        original: original,
      );
    }

    // (F) Endpoint-aware fallback for predict with useless 5xx text
    if ((p.contains('/predict') || p.endsWith('predict') || p.contains('predict')) &&
        (status != null && status >= 500) &&
        m.isEmpty) {
      return AppException(
        code: 'PREDICT_FAILED',
        title: "Couldn't process image",
        userMessage: 'Please upload a clear cattle photo with the Aruco Marker.',
        httpStatus: 400,
        original: original,
      );
    }

    return null;
  }

  /// Humanize raw backend detail for generic client errors.
  static String _humanize(String backendMsg) {
    final raw = backendMsg.trim();
    if (raw.isEmpty) return 'There was a problem with your request.';

    // Normalize/strip simple HTML if any
    final s = raw.replaceAll(RegExp(r'<[^>]+>'), ' ')
                 .replaceAll(RegExp(r'\s+'), ' ')
                 .trim();

    final lower = s.toLowerCase();

    // ---- Auth/session
    if (RegExp(r'token.*expired', caseSensitive: false).hasMatch(lower)) {
      return 'Your session expired. Please sign in again.';
    }
    if (RegExp(r'permission|forbidden', caseSensitive: false).hasMatch(lower)) {
      return 'You don’t have permission to perform this action.';
    }

    // ---- Phone / username (Bangladesh format hints)
    // Broadened: handle "user with this phone number already exists"
    if (lower.contains('already exists') &&
        (lower.contains('username') || lower.contains('phone') || lower.contains('phone number'))) {
      return 'This phone number is already registered.';
    }
    if (lower.contains('enter a valid phone') ||
        lower.contains('invalid phone') ||
        lower.contains('invalid username')) {
      return 'Enter a valid Bangladeshi phone number (e.g., 01712345678).';
    }
    if ((lower.contains('username') || lower.contains('phone') || lower.contains('phone number')) &&
        (lower.contains('required') || (lower.contains('this field') && lower.contains('required')))) {
      return 'Phone number is required.';
    }

    // ---- Password quality (Django auth style)
    if (lower.contains('password is too common')) {
      return 'Password is too weak. Choose a stronger one.';
    }
    if (lower.contains('password is too short') ||
        (lower.contains('must contain at least') && lower.contains('characters'))) {
      return 'Password must be at least 8 characters.';
    }
    if (lower.contains('password is entirely numeric') ||
        lower.contains('entirely numeric')) {
      return 'Password cannot be entirely numeric.';
    }

    // ---- Confirm password mismatch
    if (lower.contains('password') && lower.contains('match')) {
      return 'Passwords do not match.';
    }

    // Fallback: sentence-case with period.
    final first = s[0].toUpperCase() + s.substring(1);
    return first.endsWith('.') ? first : '$first.';
  }
}
