// lib/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // kDebugMode for safe debug prints
import '../utils/api.dart';               // Api (and your ApiHeaders if needed)
import 'auth_service.dart';              // for getValidAccessToken()

class PaymentService {
  static String get baseApi => Api.baseUrl;

  // Build headers with a fresh/valid access token + X-API-Key
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService().getValidAccessToken();
    final h = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-API-Key": Api.apiKey,
    };
    if (token != null && token.trim().isNotEmpty) {
      h["Authorization"] = "Bearer $token";
    }

    // Optional: masked debug log of headers
    if (kDebugMode) {
      final masked = {
        "Content-Type": h["Content-Type"],
        "X-API-Key": _mask(h["X-API-Key"]),
        "Authorization": h["Authorization"] == null
            ? null
            : "Bearer ${_mask(h["Authorization"]!.replaceFirst('Bearer ', ''))}",
      };
      // ignore: avoid_print
      print(jsonEncode(masked));
    }

    return h;
  }

  // ---------- Initiate ----------
  Future<Map<String, dynamic>> initiateShurjoPay(int packageId) async {
    try {
      final response = await http.post(
        Uri.parse(Api.initiatePayment),
        headers: await _authHeaders(),
        body: jsonEncode({"package_id": packageId}),
      );
      return _processResponse(response, _decodeJsonSafe(response));
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Checkout URL / HTML ----------
  Future<Map<String, dynamic>> fetchCheckoutUrl(String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseApi/payment/checkout-url/"),
        headers: await _authHeaders(),
        body: jsonEncode({"transaction_id": transactionId}),
      );

      final contentType = (response.headers['content-type'] ?? '').toLowerCase();
      final body = response.body;

      if (contentType.contains('application/json')) {
        return _processResponse(response, _decodeJsonSafe(response));
      }
      if (contentType.contains('text/html') ||
          body.trimLeft().toLowerCase().startsWith('<!doctype')) {
        return {
          "success": true,
          "data": {
            "html": true,
            "endpoint_get_url":
                "$baseApi/payment/checkout-url/?transaction_id=$transactionId",
          },
        };
      }
      return {
        "success": false,
        "message":
            "Unexpected response (${response.statusCode})${contentType.isNotEmpty ? ' [$contentType]' : ''}",
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Verify ShurjoPay ----------
  // Body: { "order_id": <transaction_id>, "status": "success", "sp_transaction_id": <sp id> }
  Future<Map<String, dynamic>> verifyShurjoPay({
    required String orderId,
    required String spTransactionId,
    String status = 'success',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Api.paymentVerify),
        headers: await _authHeaders(),
        body: jsonEncode({
          "order_id": orderId,
          "status": status,
          "sp_transaction_id": spTransactionId,
        }),
      );
      return _processResponse(response, _decodeJsonSafe(response));
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Optional: poll status ----------
  Future<Map<String, dynamic>> getPaymentStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseApi/payment/status/$transactionId/"),
        headers: await _authHeaders(),
      );
      return _processResponse(response, _decodeJsonSafe(response));
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Mark Failed ----------
  Future<Map<String, dynamic>> markPaymentFailed(String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse(Api.paymentFailed),
        headers: await _authHeaders(),
        body: jsonEncode({"transaction_id": transactionId}),
      );
      return _processResponse(response, _decodeJsonSafe(response));
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Cancel ----------
  Future<Map<String, dynamic>> cancelPayment(String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse(Api.paymentCancel),
        headers: await _authHeaders(),
        body: jsonEncode({"transaction_id": transactionId}),
      );
      return _processResponse(response, _decodeJsonSafe(response));
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Payment History ----------
  Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      final response = await http.get(
        Uri.parse(Api.paymentHistory),
        headers: await _authHeaders(), // sends X-API-Key + fresh Bearer
      );
      return _processResponse(response, _decodeJsonSafe(response));
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Google Play verify ----------
  Future<Map<String, dynamic>> verifyGooglePay(
    int packageId,
    String purchaseToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseApi/payment/verify-google-play/"),
        headers: await _authHeaders(),
        body: jsonEncode({
          "package_id": packageId,
          "purchase_token": purchaseToken,
        }),
      );
      return _processResponse(response, _decodeJsonSafe(response));
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ---------- Helpers ----------
  Map<String, dynamic> _decodeJsonSafe(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      final body = response.body;
      final int safeLen = body.length < 200 ? body.length : 200;
      return {
        "non_json": true,
        "status": response.statusCode,
        "content_type": response.headers['content-type'],
        "body_snippet": body.substring(0, safeLen),
      };
    }
  }

  Map<String, dynamic> _processResponse(http.Response response, dynamic data) {
    final ok = response.statusCode == 200 || response.statusCode == 201;
    if (ok) {
      return {"success": true, "data": data};
    } else {
      return {
        "success": false,
        "message": data is Map<String, dynamic>
            ? data.values.map((e) => e.toString()).join(", ")
            : "Unknown error",
      };
    }
  }

  String _mask(String? v, {int showStart = 6, int showEnd = 2}) {
    if (v == null || v.isEmpty) return "(empty)";
    if (v.length <= showStart + showEnd) return "*" * v.length;
    return "${v.substring(0, showStart)}…${v.substring(v.length - showEnd)}";
  }
}
