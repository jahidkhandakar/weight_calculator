import 'dart:io';
import 'package:dio/dio.dart';
import '../models/cow_info.dart';

class ApiService {
  static Future<CowInfo?> uploadCowImage(File imageFile) async {
    final url = 'https://1d0f-118-179-7-192.ngrok-free.app/predict';

    final dio = Dio();

    // Function to create new FormData
    FormData createFormData() {
      return FormData.fromMap({
        'file': MultipartFile.fromFileSync(imageFile.path, filename: 'cow.jpg'),
      });
    }

    try {
      // First attempt
      Response response = await dio.post(
        url,
        data: createFormData(),
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('🌐 API Status code: ${response.statusCode}');
      print('📦 API Response data: ${response.data}');

      // Handle redirect
      if (response.statusCode == 307 || response.statusCode == 302) {
        final redirectedUrl = response.headers.value('location');
        print('🔁 Redirect to: $redirectedUrl');

        if (redirectedUrl != null) {
          response = await dio.post(
            redirectedUrl,
            data: createFormData(), // 👈 NEW FormData instance
          );
        } else {
          throw Exception('Redirected but no location header found.');
        }
      }

      if (response.statusCode == 200) {
        return CowInfo(
          weight: double.parse(response.data['weight'].toString()),
          breed: response.data['breed'] ?? 'Unknown',
        );
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('❌ Upload failed: $e');
      return null;
    }
  }
}




