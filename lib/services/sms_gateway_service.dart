// lib/services/sms_gateway_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ReveSMS config (move to env/remote config later)
class SmsConfig {
  static const String baseUrl   = 'http://smpp.revesms.com:7788/sendtext';
  static const String apikey    = '7a4368474796ea35';
  static const String secretkey = '59194299';
  static const String callerID  = '12345'; // Must be approved by gateway
}

/// Simple SMS sender for OTP texts via ReveSMS.
/// Usage:
///   final res = await SmsGatewayService.sendOtp(
///     msisdn: '01799908970',
///     otp: '891645',
///     appName: 'Weight Calculator',
///   );
///   if (res['success'] == true) { ... }
class SmsGatewayService {
  /// Set true to print payload & responses during debugging.
  static bool debug = false;

  /// Sends "OTP for <appName>: <otp>" to the given Bangladeshi number.
  /// - msisdn must be 11 digits like 01XXXXXXXXX (no +880, spaces, or dashes).
  /// Returns:
  ///   { "success": true,  "data": {...} }  on Status "0"
  ///   { "success": false, "message": "...", "data": {...?} } otherwise
  static Future<Map<String, dynamic>> sendOtp({
    required String msisdn,
    required String otp,
    String appName = 'Weight Calculator',
  }) async {
    // Normalize to digits only and validate 01XXXXXXXXX
    final toUser = msisdn.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (!RegExp(r'^01\d{9}$').hasMatch(toUser)) {
      return {
        "success": false,
        "message": "Phone must be 11 digits like 01XXXXXXXXX (got: $toUser)",
      };
    }

    // Exact keys that worked in Postman
    final jsonPayload = {
      "apikey": SmsConfig.apikey,
      "secretkey": SmsConfig.secretkey,
      "callerID": SmsConfig.callerID,
      "toUser": toUser,
      "messageContent": "OTP for $appName: $otp",
    };

    // 1) Try JSON (your Postman success path)
    final jsonTry = await _postJson(jsonPayload);
    if (_isAccepted(jsonTry)) return jsonTry;

    // If gateway complains with parameter error, try form-encoded fallback
    if (debug) {
      // ignore: avoid_print
      print('[SMS] JSON failed, trying form-urlencoded fallback...');
    }

    // 2) Try x-www-form-urlencoded
    final formTry = await _postForm(jsonPayload);
    return formTry;
  }

  // -------------------- internals --------------------

  static bool _isAccepted(Map<String, dynamic> result) {
    try {
      final data = result["data"] as Map<String, dynamic>?;
      final status = data?["Status"]?.toString();
      return result["success"] == true && status == "0";
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> _postJson(
      Map<String, dynamic> payload) async {
    try {
      if (debug) {
        // ignore: avoid_print
        print('[SMS][JSON] payload: ${jsonEncode(payload)}');
      }

      final res = await http
          .post(
            Uri.parse(SmsConfig.baseUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12)); // <-- timeout

      if (debug) {
        // ignore: avoid_print
        print('[SMS][JSON] status=${res.statusCode}, body=${res.body}');
      }

      final data = _decodeBody(res.body);
      final status = data["Status"]?.toString();
      if (status == "0") {
        return {"success": true, "data": data};
      }
      return {
        "success": false,
        "message": data["Text"]?.toString() ?? "SMS Gateway error",
        "data": data,
      };
    } catch (e) {
      return {"success": false, "message": "SMS send failed (JSON): $e"};
    }
  }

  static Future<Map<String, dynamic>> _postForm(
      Map<String, dynamic> payload) async {
    try {
      final body = {
        "apikey": payload["apikey"]!,
        "secretkey": payload["secretkey"]!,
        "callerID": payload["callerID"]!,
        "toUser": payload["toUser"]!,
        "messageContent": payload["messageContent"]!,
      };

      if (debug) {
        // ignore: avoid_print
        print('[SMS][FORM] body: $body');
      }

      final res = await http
          .post(
            Uri.parse(SmsConfig.baseUrl),
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            body: body,
          )
          .timeout(const Duration(seconds: 12)); // <-- timeout

      if (debug) {
        // ignore: avoid_print
        print('[SMS][FORM] status=${res.statusCode}, body=${res.body}');
      }

      final data = _decodeBody(res.body);
      final status = data["Status"]?.toString();
      if (status == "0") {
        return {"success": true, "data": data};
      }
      return {
        "success": false,
        "message": data["Text"]?.toString() ?? "SMS Gateway error",
        "data": data,
      };
    } catch (e) {
      return {"success": false, "message": "SMS send failed (FORM): $e"};
    }
  }

  static Map<String, dynamic> _decodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      // Some gateways reply non-JSON on error
      return {"raw": body, "Status": "-1", "Text": "Non-JSON response"};
    }
  }
}
