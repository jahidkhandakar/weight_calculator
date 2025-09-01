import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../utils/api.dart';

class AuthService {
  final GetStorage storage = GetStorage();

  // ---------- Public API ----------
  Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    required String password,
    required String confirmPassword,
  }) => _post(Api.register, {
    "username": phone,
    "name": name,
    "password": password,
    "confirm_password": confirmPassword,
  }, false);

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final res = await _post(Api.login, {
      "username": phone,
      "password": password,
    }, false);
    if (res["success"] == true) {
      final data = res["data"] as Map<String, dynamic>;
      final access = data["access"]?.toString();
      final refresh = data["refresh"]?.toString();
      if (access != null && refresh != null) {
        saveTokens(access, refresh); // <-- IMPORTANT
      }
    }
    return res;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) =>
      _post(Api.refreshToken, {"refresh": refreshToken}, false);

  Future<Map<String, dynamic>> getUserDetails() => _get(Api.userDetails, true);

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

  Future<Map<String, dynamic>> requestOtp(String phone) =>
      _post(Api.requestOtp, {"phone_number": normalizeBdPhone(phone)}, false);

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) => _post(Api.verifyOtp, {
    "phone_number": normalizeBdPhone(phone),
    "otp": otp,
  }, false);

  Future<Map<String, dynamic>> verifyOtpAndSetPassword({
    required String phone,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) => _post(Api.verifyOtp, {
    "phone_number": normalizeBdPhone(phone),
    "otp": otp,
    "new_password": newPassword,
    "confirm_new_password": confirmNewPassword,
  }, false);

  // ---------- Tokens ----------
  void saveTokens(String access, String refresh) {
    storage.write('access_token', access);
    storage.write('refresh_token', refresh);
  }

  String? getToken() => storage.read('access_token');
  String? getRefreshToken() => storage.read('refresh_token');

  void logout() => storage.erase();

  //* ---------- Auto refresh access token ----------
  // In AuthService.getValidAccessToken()
  Future<String?> getValidAccessToken() async {
    final access = getToken();
    final refresh = getRefreshToken();

    // Log remaining seconds of the access token (if present)
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

    // If expired/near, refresh
    if (access == null || _isTokenExpired(access, leewaySeconds: 10)) {
      if (refresh == null) return null;
      // ignore: avoid_print
      print("[auth] refreshing access with refresh token…");
      final result = await this.refreshToken(refresh);
      // ignore: avoid_print
      print(
        "[auth] refresh result: ${result['success']} ${result['data'] ?? result['message']}",
      );
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final newAccess = data['access']?.toString();
        final newRefresh = data['refresh']?.toString() ?? refresh;
        if (newAccess != null) {
          saveTokens(newAccess, newRefresh);
          return newAccess;
        }
      } else {
        logout();
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
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now + leewaySeconds >= exp;
    } catch (_) {
      return true;
    }
  }

  // ---------- Generic HTTP helpers (with 1x refresh+retry on 401) ----------
  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
    bool useAuth,
  ) async {
    try {
      final token = useAuth ? await getValidAccessToken() : null;
      if (useAuth && token == null) {
        print('AuthService: POST blocked — no valid access token for $url');
        return {"success": false, "message": "Not authenticated", "code": 401};
      }
      final headers =
          useAuth ? ApiHeaders.authHeaders(token!) : ApiHeaders.publicHeaders;
      print('AuthService POST $url headers: $headers body: $body');

      var res = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      // 401 → try one refresh + retry once (auth calls only)
      if (useAuth && res.statusCode == 401) {
        final rTok = getRefreshToken();
        if (rTok != null && rTok.isNotEmpty) {
          final r = await refreshToken(rTok);
          print('AuthService: POST 401 → refresh result: $r');
          if (r['success'] == true) {
            final data = r['data'] as Map<String, dynamic>;
            final newAccess = data['access']?.toString();
            final newRefresh = data['refresh']?.toString() ?? rTok;
            if (newAccess != null) saveTokens(newAccess, newRefresh);
            res = await http
                .post(
                  Uri.parse(url),
                  headers: ApiHeaders.authHeaders(newAccess ?? ''),
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 20));
          } else {
            logout();
            return {
              "success": false,
              "message": "Not authenticated",
              "code": 401,
            };
          }
        }
      }

      print(
        'AuthService POST $url status: ${res.statusCode} body: ${res.body}',
      );
      return _foldHttpResponse(res);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> _get(String url, bool useAuth) async {
    try {
      final token = useAuth ? await getValidAccessToken() : null;
      if (useAuth && token == null) {
        print('AuthService: GET blocked — no valid access token for $url');
        return {"success": false, "message": "Not authenticated", "code": 401};
      }
      final headers =
          useAuth ? ApiHeaders.authHeaders(token!) : ApiHeaders.publicHeaders;
      print('AuthService GET $url headers: $headers');

      var res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (useAuth && res.statusCode == 401) {
        final rTok = getRefreshToken();
        if (rTok != null && rTok.isNotEmpty) {
          final r = await refreshToken(rTok);
          print('AuthService: GET 401 → refresh result: $r');
          if (r['success'] == true) {
            final data = r['data'] as Map<String, dynamic>;
            final newAccess = data['access']?.toString();
            final newRefresh = data['refresh']?.toString() ?? rTok;
            if (newAccess != null) saveTokens(newAccess, newRefresh);
            res = await http
                .get(
                  Uri.parse(url),
                  headers: ApiHeaders.authHeaders(newAccess ?? ''),
                )
                .timeout(const Duration(seconds: 20));
          } else {
            logout();
            return {
              "success": false,
              "message": "Not authenticated",
              "code": 401,
            };
          }
        }
      }

      print('AuthService GET $url status: ${res.statusCode} body: ${res.body}');
      return _foldHttpResponse(res);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> _put(
    String url,
    Map<String, dynamic> body,
    bool useAuth,
  ) async {
    try {
      final token = useAuth ? await getValidAccessToken() : null;
      if (useAuth && token == null) {
        print('AuthService: PUT blocked — no valid access token for $url');
        return {"success": false, "message": "Not authenticated", "code": 401};
      }
      final headers =
          useAuth ? ApiHeaders.authHeaders(token!) : ApiHeaders.publicHeaders;
      print('AuthService PUT $url headers: $headers body: $body');

      var res = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      if (useAuth && res.statusCode == 401) {
        final rTok = getRefreshToken();
        if (rTok != null && rTok.isNotEmpty) {
          final r = await refreshToken(rTok);
          print('AuthService: PUT 401 → refresh result: $r');
          if (r['success'] == true) {
            final data = r['data'] as Map<String, dynamic>;
            final newAccess = data['access']?.toString();
            final newRefresh = data['refresh']?.toString() ?? rTok;
            if (newAccess != null) saveTokens(newAccess, newRefresh);
            res = await http
                .put(
                  Uri.parse(url),
                  headers: ApiHeaders.authHeaders(newAccess ?? ''),
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 20));
          } else {
            logout();
            return {
              "success": false,
              "message": "Not authenticated",
              "code": 401,
            };
          }
        }
      }

      print('AuthService PUT $url status: ${res.statusCode} body: ${res.body}');
      return _foldHttpResponse(res);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Map<String, dynamic> _foldHttpResponse(http.Response r) {
    final bodyText = r.body;
    if (bodyText.isEmpty || !bodyText.trimLeft().startsWith('{')) {
      // Non-JSON: still surface status and raw body for debugging
      final ok = r.statusCode >= 200 && r.statusCode < 300;
      return {
        "success": ok,
        if (!ok) "message": "HTTP ${r.statusCode}",
        "code": r.statusCode,
        "raw": bodyText,
      };
    }
    final data = jsonDecode(bodyText);
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) return {"success": true, "data": data};
    return {
      "success": false,
      "message": _parseError(data),
      "code": r.statusCode,
      "data": data,
    };
  }

  // ---------- Error parse ----------
  String _parseError(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      return data.values
          .map((e) => e is List ? e.join(', ') : e.toString())
          .join(' | ');
    }
    return "Unknown error";
  }

  // ---------- Phone helpers ----------
  String? validateBdPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final okLocal = RegExp(r'^01\d{9}$').hasMatch(digits);
    final okIntl = RegExp(r'^8801\d{9}$').hasMatch(digits);
    if (okLocal || okIntl) return null;
    return 'Enter a valid BD number (e.g., 017XXXXXXXX)';
  }

  String normalizeBdPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880') && digits.length == 13) {
      return '0${digits.substring(3)}'; // 88017... -> 017...
    }
    if (digits.startsWith('01') && digits.length == 11) return digits;
    return raw.trim();
  }
}
