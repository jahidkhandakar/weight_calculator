// lib/mvc/models/package_model.dart
import 'dart:convert';

class PackageModel {
  final int id;
  final String name;
  final int credit;
  final String price;  // keep as String (backend may send number/string)
  final String description;

  PackageModel({
    required this.id,
    required this.name,
    required this.credit,
    required this.price,
    required this.description,
  });

  /// Backward-compatible: you already had fromJson(Map)
  factory PackageModel.fromJson(Map<String, dynamic> json) =>
      PackageModel.fromMap(json);

  /// New: tolerant parser for different backend shapes
  factory PackageModel.fromMap(Map<String, dynamic> map) {
    final id = _asInt(map, const ['id', 'package_id']) ?? 0;
    final name = _asString(map, const ['name', 'package_name', 'title']) ?? '';
    final credit =
        _asInt(map, const ['credit', 'credits', 'credit_amount']) ?? 0;
    final price = _asString(map, const [
          'price',
          'amount',
          'cost',
          'price_bdt',
          'price_tk',
        ]) ??
        '';
    final description =
        _asString(map, const ['description', 'desc', 'details']) ?? '';

    return PackageModel(
      id: id,
      name: name,
      credit: credit,
      price: price,
      description: description,
    );
  }

  /// Handy if you ever receive a JSON string
  factory PackageModel.fromJsonString(String source) =>
      PackageModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'credit': credit,
        'price': price,
        'description': description,
      };

  String toJson() => jsonEncode(toMap());

  PackageModel copyWith({
    int? id,
    String? name,
    int? credit,
    String? price,
    String? description,
  }) {
    return PackageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      credit: credit ?? this.credit,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }

  // ---- Utilities ----

  static String? _asString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is String) return v;
      if (v is num || v is bool) return v.toString();
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
        final x = int.tryParse(v);
        if (x != null) return x;
        final d = double.tryParse(v);
        if (d != null) return d.round();
      }
    }
    return null;
  }

  /// Optional helper: parse a list from various shapes
  static List<PackageModel> listFrom(dynamic data) {
    final out = <PackageModel>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) out.add(PackageModel.fromMap(e));
      }
      return out;
    }
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['results'],
        data['packages'],
        data['data'], // sometimes list is under "data"
      ];
      for (final c in candidates) {
        if (c is List) {
          for (final e in c) {
            if (e is Map<String, dynamic>) out.add(PackageModel.fromMap(e));
          }
          if (out.isNotEmpty) return out;
        }
      }
    }
    return out;
  }
}
