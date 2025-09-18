// lib/services/prediction_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:dio/dio.dart';
import '../utils/api.dart';
import 'package:weight_calculator/utils/errors/error_mapper.dart';

class PredictionService {
  // Dio v5: timeouts are Durations; validateStatus lets non-2xx pass through.
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => true,
    ),
  );

  /// Uploads a cattle image for weight prediction (Bearer required).
  /// On any error, throws AppException via ErrorMapper so UI shows one snackbar.
  Future<Map<String, dynamic>> predict(File imageFile, String token) async {
    try {
      final formData = FormData.fromMap({
        // If your backend expects a different field name, change 'file'.
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'cow.jpg',
        ),
      });

      final response = await _dio.post(
        Api.predict,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': Api.apiKey,
            // Do NOT set 'Content-Type' for multipart; Dio adds the boundary.
          },
        ),
      );

      final status = response.statusCode ?? 0;

      if (status >= 200 && status < 300) {
        final data = response.data;
        return {
          "success": true,
          "data": data is Map ? data : {"raw": data},
        };
      }

      // Debug: print the server response so we can see what came back.
      _debugDumpResponse(response);

      // Non-2xx → mapped to user-friendly AppException (NO_CATTLE/NO_MARKER/etc.).
      throw ErrorMapper.toAppException(response);
    } on DioException catch (e) {
      // Network/timeout/etc. (Dio v5)
      if (kDebugMode) {
        final r = e.response;
        if (r != null) _debugDumpResponse(r, tag: '[predict][DioException]');
      }
      throw ErrorMapper.toAppException(e);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }

  // -------------------- Debug helpers --------------------

  void _debugDumpResponse(Response resp, {String tag = '[predict]'}) {
    if (!kDebugMode) return;
    try {
      final method = resp.requestOptions.method;
      final uri = resp.requestOptions.uri; // includes base + path + query
      final status = resp.statusCode;
      final ct = resp.headers.value('content-type');

      // Body → stringify safely & truncate
      String body;
      final data = resp.data;
      if (data is String) {
        body = data;
      } else {
        try {
          body = jsonEncode(data);
        } catch (_) {
          body = data?.toString() ?? '';
        }
      }
      if (body.length > 1200) {
        body = body.substring(0, 1200) + '… [truncated]';
      }

      // Mask sensitive headers if you ever log them (we don’t here)
      // final auth = resp.requestOptions.headers['Authorization'];

      // ignore: avoid_print
      print(
        '$tag $method $uri -> $status ($ct)\n'
        '$body\n'
        '--- end of server response ---',
      );
    } catch (e) {
      // ignore: avoid_print
      print('$tag debug dump failed: $e');
    }
  }
}
