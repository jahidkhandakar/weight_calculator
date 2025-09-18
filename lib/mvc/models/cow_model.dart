import 'dart:convert';

class CowModel {
  final double weight;                 // in kg
  final String breed;                  // e.g., "Sahiwal"
  final int creditsRemaining;          // remaining credits after this call
  final String processedImage;         // URL/base64 of annotated/processed image
  final Map<String, dynamic> keypoints; // landmarks/pose/keypoints

  CowModel({
    required this.weight,
    required this.breed,
    required this.creditsRemaining,
    required this.processedImage,
    required this.keypoints,
  });

  /// Backward-compatible with your existing code
  factory CowModel.fromJson(Map<String, dynamic> json) => CowModel.fromMap(json);

  /// Robust parser that tolerates different API shapes and nested keys.
  factory CowModel.fromMap(Map<String, dynamic> map) {
    // Some backends wrap payloads under "data", "result", "payload"
    final root = _unwrap(map, keys: const ['data', 'result', 'payload']);

    // If server returns a list (e.g., detections), pick the first cow-like item
    final obj = _pickCowLike(root);

    final double weight = _asDouble(obj, const [
          'weight',
          'weight_kg',
          'predicted_weight',
          'prediction.weight',
          'result.weight_kg',
          'est_weight',
        ]) ??
        0.0;

    final String breed = _asString(obj, const [
          'breed',
          'predicted_breed',
          'cattle_breed',
          'prediction.breed',
          'result.breed',
        ]) ??
        'Unknown';

    final int creditsRemaining = _asInt(obj, const [
          'credits_remaining',
          'remaining_credits',
          'remaining',
          'credits',
          'credit',
        ]) ??
        0;

    // Processed/annotated image URL or base64
    final String processedImage = _asString(obj, const [
          'processed_image',
          'annotated_image',
          'output_image',
          'image_url',
          'preview_image',
          'result.processed_image',
          'result.image_url',
        ]) ??
        '';

    // Keypoints / landmarks; support both Map and List
    final Map<String, dynamic> keypoints = _asMap(obj, const [
          'keypoints',
          'landmarks',
          'points',
          'pose',
          'skeleton',
          'prediction.keypoints',
        ]) ??
        const {};

    return CowModel(
      weight: weight,
      breed: breed,
      creditsRemaining: creditsRemaining,
      processedImage: processedImage,
      keypoints: keypoints,
    );
  }

  /// Also handy in case of a raw JSON string.
  factory CowModel.fromJsonString(String source) =>
      CowModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
        'weight': weight,
        'breed': breed,
        'credits_remaining': creditsRemaining,
        'processed_image': processedImage,
        'keypoints': keypoints,
      };

  String toJson() => jsonEncode(toMap());

  CowModel copyWith({
    double? weight,
    String? breed,
    int? creditsRemaining,
    String? processedImage,
    Map<String, dynamic>? keypoints,
  }) {
    return CowModel(
      weight: weight ?? this.weight,
      breed: breed ?? this.breed,
      creditsRemaining: creditsRemaining ?? this.creditsRemaining,
      processedImage: processedImage ?? this.processedImage,
      keypoints: keypoints ?? this.keypoints,
    );
  }

  // --------------------------- Helpers --------------------------- //

  /// Unwraps common single-nesting containers like {"data": {...}}
  static Map<String, dynamic> _unwrap(Map<String, dynamic> m,
      {required List<String> keys}) {
    for (final k in keys) {
      final v = m[k];
      if (v is Map<String, dynamic>) return v;
    }
    return m;
  }

  /// If the root contains a list of objects (detections/results), pick a cow-like one.
  static Map<String, dynamic> _pickCowLike(Map<String, dynamic> root) {
    for (final key in const ['detections', 'objects', 'results', 'items']) {
      final v = root[key];
      if (v is List && v.isNotEmpty) {
        final firstMap = v.firstWhere(
          (e) =>
              e is Map<String, dynamic> &&
              _looksLikeCow(e as Map<String, dynamic>),
          orElse: () => v.first,
        );
        if (firstMap is Map<String, dynamic>) return firstMap;
      }
    }
    return root;
  }

  static bool _looksLikeCow(Map<String, dynamic> m) {
    final label = _asString(m, const ['label', 'class', 'name', 'object'])
        ?.toLowerCase();
    if (label != null && (label.contains('cow') || label.contains('cattle'))) {
      return true;
    }
    final flags = _asBool(m, const [
      'cow_detected',
      'cattle_detected',
      'is_cow',
      'is_cattle',
      'object_is_cow',
    ]);
    return flags == true;
  }

  /// Supports dotted paths like "prediction.weight"
  static dynamic _get(Map<String, dynamic> m, String path) {
    if (!path.contains('.')) return m[path];
    dynamic cur = m;
    for (final seg in path.split('.')) {
      if (cur is Map<String, dynamic>) {
        cur = cur[seg];
      } else {
        return null;
      }
    }
    return cur;
  }

  static String? _asString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = _get(m, k);
      if (v == null) continue;
      if (v is String && v.trim().isNotEmpty) return v;
      if (v is num || v is bool) return v.toString();
      // Some APIs return nested {"url": "..."} for images
      if (v is Map && v['url'] is String) return (v['url'] as String);
    }
    return null;
  }

  static double? _asDouble(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = _get(m, k);
      if (v == null) continue;
      if (v is num) return v.toDouble();
      if (v is String) {
        final x = double.tryParse(v);
        if (x != null) return x;
      }
    }
    return null;
  }

  static int? _asInt(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = _get(m, k);
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

  static bool? _asBool(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = _get(m, k);
      if (v == null) continue;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'true' || s == 'yes' || s == '1' || s == 'healthy') return true;
        if (s == 'false' || s == 'no' || s == '0' || s == 'unhealthy') return false;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = _get(m, k);
      if (v == null) continue;
      if (v is Map<String, dynamic>) return v;
      if (v is List) {
        // Convert list of points to a map with indices or named keys if present
        return {
          "items": v,
        };
      }
      if (v is String) {
        // Some APIs send keypoints as JSON string
        try {
          final parsed = jsonDecode(v);
          if (parsed is Map<String, dynamic>) return parsed;
          if (parsed is List) return {"items": parsed};
        } catch (_) {}
      }
    }
    return null;
  }
}
