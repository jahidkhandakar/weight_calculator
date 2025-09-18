// lib/mvc/models/payment_model.dart
import 'dart:convert';

class PaymentModel {
  final String transactionId; // e.g., "5d8a7d21-b504-4cc4-944f-753bbb0d7692"
  final double amount;        // e.g., 100.0
  final String packageName;   // e.g., "Basic"
  final int credit;           // e.g., 10
  final String status;        // e.g., "success" | "failed" | "pending" | "canceled"

  PaymentModel({
    required this.transactionId,
    required this.amount,
    required this.packageName,
    required this.credit,
    required this.status,
  });

  /// Backward-compatible with your existing code.
  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      PaymentModel.fromMap(json);

  /// New: tolerant parser for different backend shapes.
  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    final id = _asString(map, const [
          'transaction_id',
          'order_id',
          'id',
          'txn_id',
        ]) ??
        '';

    final amount = _asDouble(map, const [
          'amount',
          'price',
          'total',
          'paid_amount',
          'grand_total',
        ]) ??
        0.0;

    final packageName = _asString(map, const [
          'package_name',
          'name',
          'package',
          'plan_name',
        ]) ??
        '';

    final credit = _asInt(map, const [
          'credit',
          'credits',
          'credit_amount',
        ]) ??
        0;

    final rawStatus = _asString(map, const [
          'status',
          'payment_status',
          'state',
          'result',
        ]) ??
        '';
    final status = _normalizeStatus(rawStatus);

    return PaymentModel(
      transactionId: id,
      amount: amount,
      packageName: packageName,
      credit: credit,
      status: status,
    );
  }

  /// Optional: construct from a JSON string
  factory PaymentModel.fromJsonString(String source) =>
      PaymentModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
        'transaction_id': transactionId,
        'amount': amount,
        'package_name': packageName,
        'credit': credit,
        'status': status,
      };

  String toJson() => jsonEncode(toMap());

  PaymentModel copyWith({
    String? transactionId,
    double? amount,
    String? packageName,
    int? credit,
    String? status,
  }) {
    return PaymentModel(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      packageName: packageName ?? this.packageName,
      credit: credit ?? this.credit,
      status: status ?? this.status,
    );
  }

  // ---------------- Helpers ----------------

  static String _normalizeStatus(String s) {
    final v = s.toLowerCase().trim();
    if (v.isEmpty) return 'unknown';
    if (v.contains('success') || v.contains('paid') || v.contains('complete')) {
      return 'success';
    }
    if (v.contains('fail') || v.contains('declin') || v.contains('error')) {
      return 'failed';
    }
    if (v.contains('cancel')) return 'canceled';
    if (v.contains('pend') || v.contains('process')) return 'pending';
    return v; // keep original if none matched
    }

  static String? _asString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is String) return v;
      if (v is num || v is bool) return v.toString();
    }
    return null;
  }

  static double? _asDouble(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      if (v is String) {
        final d = double.tryParse(v);
        if (d != null) return d;
        // handle "100" -> 100.0 when it's actually int as string
        final i = int.tryParse(v);
        if (i != null) return i.toDouble();
      }
    }
    return null;
  }

  static int? _asInt(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final i = int.tryParse(v);
        if (i != null) return i;
        final d = double.tryParse(v);
        if (d != null) return d.round();
      }
    }
    return null;
  }

  /// Helper to parse a list of payments from various shapes.
  static List<PaymentModel> listFrom(dynamic data) {
    final out = <PaymentModel>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) out.add(PaymentModel.fromMap(e));
      }
      return out;
    }
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['results'],
        data['payments'],
        data['data'], // sometimes list is under "data"
      ];
      for (final c in candidates) {
        if (c is List) {
          for (final e in c) {
            if (e is Map<String, dynamic>) out.add(PaymentModel.fromMap(e));
          }
          if (out.isNotEmpty) return out;
        }
      }
    }
    return out;
  }
}
