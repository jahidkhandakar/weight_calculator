// lib/services/payment_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kDebugMode for masked header logs
import 'package:http/http.dart' as http;
import '../utils/api.dart';               // Api + Api.baseUrl, Api.apiKey, endpoints
import 'auth_service.dart';              // for getValidAccessToken()
import 'package:weight_calculator/utils/errors/error_mapper.dart';

class PaymentService {
  static String get baseApi => Api.baseUrl;

  // Build headers with a fresh/valid access token + X-API-Key
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService().getValidAccessToken();
    final h = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-API-Key": Api.apiKey, // or Api.xApiKey if that's your constant
    };
    if (token != null && token.trim().isNotEmpty) {
      h["Authorization"] = "Bearer $token";
    }

    // Optional masked debug log
    if (kDebugMode) {
      final masked = {
        "Content-Type": h["Content-Type"],
        "X-API-Key": _mask(h["X-API-Key"]),
        "Authorization": h["Authorization"] == null
            ? null
            : "Bearer ${_mask(h["Authorization"]!.replaceFirst('Bearer ', ''))}",
      };
      // ignore: avoid_print
      print("[payment] headers: ${jsonEncode(masked)}");
    }

    return h;
  }

  // ------------------------- Endpoints ------------------------- //

  /// Start a ShurjoPay transaction for a package
  Future<Map<String, dynamic>> initiateShurjoPay(int packageId) async {
    try {
      final r = await http.post(
        Uri.parse(Api.initiatePayment),
        headers: await _authHeaders(),
        body: jsonEncode({"package_id": packageId}),
      );
      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// Get checkout HTML (some backends return raw HTML here)
  Future<Map<String, dynamic>> fetchCheckoutUrl(String transactionId) async {
    try {
      final r = await http.post(
        Uri.parse("$baseApi/payment/checkout-url/"),
        headers: await _authHeaders(),
        body: jsonEncode({"transaction_id": transactionId}),
      );

      final contentType = (r.headers['content-type'] ?? '').toLowerCase();
      final body = r.body;

      if (contentType.contains('text/html') ||
          body.trimLeft().toLowerCase().startsWith('<!doctype')) {
        return {"success": true, "data": {"html": body}};
      }

      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// Verify ShurjoPay result
  Future<Map<String, dynamic>> verifyShurjoPay({
    required String orderId,
    required String spTransactionId,
    String status = 'success',
  }) async {
    try {
      final r = await http.post(
        Uri.parse(Api.paymentVerify),
        headers: await _authHeaders(),
        body: jsonEncode({
          "order_id": orderId,
          "status": status,
          "sp_transaction_id": spTransactionId,
        }),
      );
      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// Optional: poll payment status
  Future<Map<String, dynamic>> getPaymentStatus(String transactionId) async {
    try {
      final r = await http.get(
        Uri.parse("$baseApi/payment/status/$transactionId/"),
        headers: await _authHeaders(),
      );
      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// Mark failed
  Future<Map<String, dynamic>> markPaymentFailed(String transactionId) async {
    try {
      final r = await http.post(
        Uri.parse(Api.paymentFailed),
        headers: await _authHeaders(),
        body: jsonEncode({"transaction_id": transactionId}),
      );
      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// Cancel payment
  Future<Map<String, dynamic>> cancelPayment(String transactionId) async {
    try {
      final r = await http.post(
        Uri.parse(Api.paymentCancel),
        headers: await _authHeaders(),
        body: jsonEncode({"transaction_id": transactionId}),
      );
      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// History
  Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      final r = await http.get(
        Uri.parse(Api.paymentHistory),
        headers: await _authHeaders(),
      );
      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  /// Google Play verification
  Future<Map<String, dynamic>> verifyGooglePay(
    int packageId,
    String purchaseToken,
  ) async {
    try {
      final r = await http.post(
        Uri.parse("$baseApi/payment/verify-google-play/"),
        headers: await _authHeaders(),
        body: jsonEncode({
          "package_id": packageId,
          "purchase_token": purchaseToken,
        }),
      );
      return _okOrThrow(r);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  //--------------------------- Helpers ---------------------------//

  Map<String, dynamic> _okOrThrow(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final t = r.body.trimLeft();
      final data =
          t.isNotEmpty && t.startsWith('{') ? jsonDecode(t) : {"raw": r.body};
      return {"success": true, "data": data};
    }
    throw ErrorMapper.toAppException(r, statusCode: r.statusCode);
  }

  String _mask(String? v, {int showStart = 6, int showEnd = 2}) {
    if (v == null || v.isEmpty) return "(empty)";
    if (v.length <= showStart + showEnd) return "*" * v.length;
    return "${v.substring(0, showStart)}…${v.substring(v.length - showEnd)}";
  }
}
