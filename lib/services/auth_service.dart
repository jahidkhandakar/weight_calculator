// lib/services/auth_service.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'package:weight_calculator/utils/phone_number_helper.dart';
import '../utils/api.dart';

import 'package:weight_calculator/utils/errors/app_exception.dart';
import 'package:weight_calculator/utils/errors/error_mapper.dart';

class AuthService {
  final GetStorage storage = GetStorage();

  //--------------------------- Public API ---------------------------//

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    required String password,
    required String confirmPassword,
  }) {
    return _post(
      Api.register,
      {
        "username": phone, // keep as-is if backend expects username=phone
        "name": name,
        "password": password,
        "confirm_password": confirmPassword,
      },
      false,
    );
  }

  /// Login with phone/password and persist tokens on success
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final res = await _post(
      Api.login,
      {
        "username": phone, // or normalizeBdPhone(phone) if backend expects it
        "password": password,
      },
      false,
    );

    if (res["success"] == true) {
      final data = res["data"] as Map<String, dynamic>;
      final access = data["access"]?.toString();
      final refresh = data["refresh"]?.toString();
      if (access != null && refresh != null) {
        await saveTokens(access, refresh);
      }
    }
    return res;
  }

  /// Refresh the access token using a refresh token
  /// Returns a success=false map on failure (don’t throw here to simplify callers)
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      return await _post(Api.refreshToken, {"refresh": refreshToken}, false);
    } catch (_) {
      return {"success": false, "message": "Refresh failed"};
    }
  }

  /// Fetch current user details (requires auth)
  Future<Map<String, dynamic>> getUserDetails() => _get(Api.userDetails, true);

  /// Change password (requires auth)
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    String? confirmNewPassword,
  }) {
    final body = {
      "old_password": oldPassword,
      "new_password": newPassword,
      if (confirmNewPassword != null) "confirm_new_password": confirmNewPassword,
    };
    return _put(Api.changePassword, body, true);
  }

  /// Request OTP for password reset (public)
  Future<Map<String, dynamic>> requestOtp(String phone) {
    return _post(
      Api.requestOtp,
      {"phone_number": normalizeBdPhone(phone)},
      false,
    );
  }

  /// Verify OTP (public)
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) {
    return _post(
      Api.verifyOtp,
      {
        "phone_number": normalizeBdPhone(phone),
        "otp": otp,
      },
      false,
    );
  }

  /// Verify OTP and set new password (public)
  Future<Map<String, dynamic>> verifyOtpAndSetPassword({
    required String phone,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return _post(
      Api.verifyOtp, // adjust if you have a different endpoint
      {
        "phone_number": normalizeBdPhone(phone),
        "otp": otp,
        "new_password": newPassword,
        "confirm_new_password": confirmNewPassword,
      },
      false,
    );
  }

  // ------------------------ Token Utilities ------------------------ //

  Future<void> saveTokens(String access, String refresh) async {
    await storage.write('access_token', access);
    await storage.write('refresh_token', refresh);
  }

  String? getToken() => storage.read('access_token');
  String? getRefreshToken() => storage.read('refresh_token');

  Future<void> logout() async {
    await storage.erase();
  }

  /// Returns a valid access token or null if refresh failed.
  /// - If the access token is near expiry, attempts a refresh once.
  Future<String?> getValidAccessToken() async {
    final access = getToken();
    final refresh = getRefreshToken();

    // Debug: log remaining seconds (best-effort)
    if (access != null) {
      try {
        final parts = access.split('.');
        final payload =
            jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final exp = (payload['exp'] as num).toInt();
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final left = exp - now;
        // ignore: avoid_print
        print("[auth] access expires in ${left}s");
      } catch (_) {}
    }

    // If expired or close to expiry, refresh
    if (access == null || _isTokenExpired(access, leewaySeconds: 10)) {
      if (refresh == null) return null;
      // ignore: avoid_print
      print("[auth] refreshing access with refresh token…");

      final result = await refreshToken(refresh);
      // ignore: avoid_print
      print("[auth] refresh result: ${result['success']} ${result['data'] ?? result['message']}");

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final newAccess = data['access']?.toString();
        final newRefresh = data['refresh']?.toString() ?? refresh;
        if (newAccess != null) {
          await saveTokens(newAccess, newRefresh);
          return newAccess;
        }
      } else {
        await logout();
        return null;
      }
    }
    return access;
  }

  bool _isTokenExpired(String token, {int leewaySeconds = 0}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = (payload['exp'] as int);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now + leewaySeconds >= exp;
    } catch (_) {
      return true;
    }
  }

  // --------------- Generic HTTP (with 1x refresh & retry) --------------- //

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
    bool useAuth,
  ) async {
    try {
      final uri = Uri.parse(url);
      final payload = jsonEncode(body);

      final http.Response res = useAuth
          ? await _authedOnceWithRefresh(
              (t) => http.post(uri, headers: ApiHeaders.authHeaders(t), body: payload),
            )
          : await http
              .post(uri, headers: ApiHeaders.publicHeaders, body: payload)
              .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final text = res.body.trimLeft();
        return {
          "success": true,
          "data": text.isEmpty ? {} : jsonDecode(text),
        };
      }
      throw ErrorMapper.toAppException(res, statusCode: res.statusCode);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  Future<Map<String, dynamic>> _get(String url, bool useAuth) async {
    try {
      final uri = Uri.parse(url);

      final http.Response res = useAuth
          ? await _authedOnceWithRefresh(
              (t) => http.get(uri, headers: ApiHeaders.authHeaders(t)),
            )
          : await http
              .get(uri, headers: ApiHeaders.publicHeaders)
              .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final text = res.body.trimLeft();
        return {
          "success": true,
          "data": text.isNotEmpty && text.startsWith('{')
              ? jsonDecode(text)
              : {"raw": res.body},
        };
      }
      throw ErrorMapper.toAppException(res, statusCode: res.statusCode);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  Future<Map<String, dynamic>> _put(
    String url,
    Map<String, dynamic> body,
    bool useAuth,
  ) async {
    try {
      final uri = Uri.parse(url);
      final payload = jsonEncode(body);

      final http.Response res = useAuth
          ? await _authedOnceWithRefresh(
              (t) => http.put(uri, headers: ApiHeaders.authHeaders(t), body: payload),
            )
          : await http
              .put(uri, headers: ApiHeaders.publicHeaders, body: payload)
              .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final text = res.body.trimLeft();
        return {
          "success": true,
          "data": text.isEmpty ? {} : jsonDecode(text),
        };
      }
      throw ErrorMapper.toAppException(res, statusCode: res.statusCode);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// Performs an authenticated request; if the first attempt returns 401,
  /// tries to refresh the token once and retries the original request.
  Future<http.Response> _authedOnceWithRefresh(
    Future<http.Response> Function(String token) doRequest,
  ) async {
    final token = await getValidAccessToken();
    if (token == null) {
      throw AppException.authExpired();
    }

    var res = await doRequest(token).timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      final rTok = getRefreshToken();
      if (rTok == null || rTok.isEmpty) {
        await logout();
        throw AppException.authExpired(original: res);
      }

      final r = await refreshToken(rTok);
      if (r['success'] == true) {
        final data = r['data'] as Map<String, dynamic>;
        final newAccess = data['access']?.toString();
        final newRefresh = data['refresh']?.toString() ?? rTok;
        if (newAccess != null) {
          await saveTokens(newAccess, newRefresh);
          res = await doRequest(newAccess).timeout(const Duration(seconds: 20));
        } else {
          await logout();
          throw AppException.authExpired(original: res);
        }
      } else {
        await logout();
        throw AppException.authExpired(original: res);
      }
    }
    return res;
    // All non-2xx errors are handled by callers via ErrorMapper in _post/_get/_put.
  }
}
