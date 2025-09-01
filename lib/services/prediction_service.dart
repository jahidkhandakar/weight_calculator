import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/api.dart';

class PredictionService {
  final Dio _dio = Dio();

  /// Uploads a cattle image for weight prediction.
  /// Requires access token for authentication.
  Future<Map<String, dynamic>> predict(File imageFile, String token) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: 'cow.jpg'),
      });

      final response = await _dio.post(
        Api.predict,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "X-API-Key": Api.apiKey,
            "Accept": "application/json",  
          },
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": response.data};
      } else {
        return {
          "success": false,
          "message": response.data is Map
              ? response.data.values.map((e) => e.toString()).join(", ")
              : "Unexpected error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
