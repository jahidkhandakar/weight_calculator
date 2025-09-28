// lib/services/auth_service.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:weight_calculator/utils/phone_number_helper.dart';
import '../utils/api.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';
import 'package:weight_calculator/utils/errors/error_mapper.dart';
import 'sms_gateway_service.dart';

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
    return _post(Api.register, {
      "username": phone, // keep as-is if backend expects username=phone
      "name": name,
      "password": password,
      "confirm_password": confirmPassword,
    }, false);
  }

  /// Login with phone/password and persist tokens on success
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final res = await _post(Api.login, {
      "username": phone, // or normalizeBdPhone(phone) if backend expects it
      "password": password,
    }, false);

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
      if (confirmNewPassword != null)
        "confirm_new_password": confirmNewPassword,
    };
    return _put(Api.changePassword, body, true);
  }

  //* Request OTP (public)
  // Request OTP from backend, then send it via ReveSMS gateway.
  // Returns { success: bool, message: String } (does not expose OTP in production)
  Future<Map<String, dynamic>> requestOtp(String rawPhone) async {
    // 1) Normalize + validate BD phone (expects 01XXXXXXXXX for SMS gateway)
    final phone = normalizeBdPhone(rawPhone).trim();
    if (phone.isEmpty) {
      return {"success": false, "message": "Phone number is required"};
    }

    try {
      // 2) Ask your backend for an OTP
      final res = await http.post(
        Uri.parse(Api.requestOtp),
        headers: {
          "Content-Type": "application/json",
          "X-API-Key": Api.apiKey, // REQUIRED by your backend
        },
        body: jsonEncode({
          "phone_number": phone,
        }), // backend expects "phone_number"
      );

      // 3) Safely decode body (even on non-200)
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        data = {"raw": res.body};
      }

      if (res.statusCode != 200) {
        final msg =
            (data["detail"] ?? data["message"] ?? "Failed to request OTP")
                .toString();
        return {"success": false, "message": msg};
      }

      // 4) Extract OTP from backend
      final otp = (data["otp"] ?? "").toString();
      if (otp.isEmpty) {
        return {"success": false, "message": "OTP not returned by server"};
      }

      // 5) Send OTP via ReveSMS (no X-API-Key header here)
      final sms = await SmsGatewayService.sendOtp(msisdn: phone, otp: otp);
      if (sms["success"] != true) {
        // Bubble up the exact SMS gateway reason (e.g., "Inappropriate request parameter")
        final msg = (sms["message"] ?? "Failed to send OTP via SMS").toString();
        return {"success": false, "message": "SMS Gateway error: $msg"};
      }

      // 6) Optional: persist cooldown metadata
      storage.write('last_otp_phone', phone);
      storage.write('last_otp_sent_at', DateTime.now().millisecondsSinceEpoch);

      return {
        "success": true,
        "message": (data["message"] ?? "OTP sent").toString(),
        "data": {"phone_number": phone},
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  //* Verify OTP (public)
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) {
    return _post(Api.verifyOtp, {
      "phone_number": normalizeBdPhone(phone),
      "otp": otp,
    }, false);
  }

  //* Verify OTP + set new password
  Future<Map<String, dynamic>> verifyOtpAndSetPassword({
    required String phone,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(Api.verifyOtp),
        headers: {"Content-Type": "application/json", "X-API-Key": Api.apiKey},
        body: jsonEncode({
          "phone_number": phone,
          "otp": otp,
          "new_password": newPassword,
          "confirm_new_password": confirmNewPassword,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        // save tokens if provided
        if (data["access"] != null)
          storage.write('access_token', data["access"]);
        if (data["refresh"] != null)
          storage.write('refresh_token', data["refresh"]);
        return {
          "success": true,
          "message": data["message"] ?? "Verified",
          "data": data,
        };
      } else {
        return {
          "success": false,
          "message": data["detail"] ?? "Verification failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
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
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
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
      print(
        "[auth] refresh result: ${result['success']} ${result['data'] ?? result['message']}",
      );

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
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = (payload['exp'] as int);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now + leewaySeconds >= exp;
    } catch (_) {
      return true;
    }
  }

  // --------------- Generic HTTP (with 1x refresh & retry) --------------- //
  //*_____________________________POST________________________________//
  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
    bool useAuth,
  ) async {
    try {
      final uri = Uri.parse(url);
      final payload = jsonEncode(body);

      final http.Response res =
          useAuth
              ? await _authedOnceWithRefresh(
                (t) => http.post(
                  uri,
                  headers: ApiHeaders.authHeaders(t),
                  body: payload,
                ),
              )
              : await http
                  .post(uri, headers: ApiHeaders.publicHeaders, body: payload)
                  .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final text = res.body.trimLeft();
        return {"success": true, "data": text.isEmpty ? {} : jsonDecode(text)};
      }
      throw ErrorMapper.toAppException(res, statusCode: res.statusCode);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  //*_____________________________GET________________________________//
  Future<Map<String, dynamic>> _get(String url, bool useAuth) async {
    try {
      final uri = Uri.parse(url);

      final http.Response res =
          useAuth
              ? await _authedOnceWithRefresh(
                (t) => http.get(uri, headers: ApiHeaders.authHeaders(t)),
              )
              : await http
                  .get(uri, headers: ApiHeaders.publicHeaders)
                  .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final text = res.body.trim();
        if (text.isEmpty) {
          return {"success": true, "data": []};
        }

        final decoded = jsonDecode(text);
        return {"success": true, "data": decoded};
      }

      throw ErrorMapper.toAppException(res, statusCode: res.statusCode);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }
  //*_____________________________PUT________________________________//
  Future<Map<String, dynamic>> _put(
    String url,
    Map<String, dynamic> body,
    bool useAuth,
  ) async {
    try {
      final uri = Uri.parse(url);
      final payload = jsonEncode(body);

      final http.Response res =
          useAuth
              ? await _authedOnceWithRefresh(
                (t) => http.put(
                  uri,
                  headers: ApiHeaders.authHeaders(t),
                  body: payload,
                ),
              )
              : await http
                  .put(uri, headers: ApiHeaders.publicHeaders, body: payload)
                  .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final text = res.body.trimLeft();
        return {"success": true, "data": text.isEmpty ? {} : jsonDecode(text)};
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

  //*_________________Payment History__________________*//
  Future<Map<String, dynamic>> getPaymentHistory() =>
      _get(Api.paymentHistory, true);
}
